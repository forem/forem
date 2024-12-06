package org.jruby.puma;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.Block;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLEngineResult;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.SSLSession;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

import static javax.net.ssl.SSLEngineResult.Status;
import static javax.net.ssl.SSLEngineResult.HandshakeStatus;

public class MiniSSL extends RubyObject {
  private static ObjectAllocator ALLOCATOR = new ObjectAllocator() {
    public IRubyObject allocate(Ruby runtime, RubyClass klass) {
      return new MiniSSL(runtime, klass);
    }
  };

  public static void createMiniSSL(Ruby runtime) {
    RubyModule mPuma = runtime.defineModule("Puma");
    RubyModule ssl = mPuma.defineModuleUnder("MiniSSL");

    mPuma.defineClassUnder("SSLError",
                           runtime.getClass("IOError"),
                           runtime.getClass("IOError").getAllocator());

    RubyClass eng = ssl.defineClassUnder("Engine",runtime.getObject(),ALLOCATOR);
    eng.defineAnnotatedMethods(MiniSSL.class);
  }

  /**
   * Fairly transparent wrapper around {@link java.nio.ByteBuffer} which adds the enhancements we need
   */
  private static class MiniSSLBuffer {
    ByteBuffer buffer;

    private MiniSSLBuffer(int capacity) { buffer = ByteBuffer.allocate(capacity); }
    private MiniSSLBuffer(byte[] initialContents) { buffer = ByteBuffer.wrap(initialContents); }

    public void clear() { buffer.clear(); }
    public void compact() { buffer.compact(); }
    public void flip() { ((Buffer) buffer).flip(); }
    public boolean hasRemaining() { return buffer.hasRemaining(); }
    public int position() { return buffer.position(); }

    public ByteBuffer getRawBuffer() {
      return buffer;
    }

    /**
     * Writes bytes to the buffer after ensuring there's room
     */
    private void put(byte[] bytes, final int offset, final int length) {
      if (buffer.remaining() < length) {
        resize(buffer.limit() + length);
      }
      buffer.put(bytes, offset, length);
    }

    /**
     * Ensures that newCapacity bytes can be written to this buffer, only re-allocating if necessary
     */
    public void resize(int newCapacity) {
      if (newCapacity > buffer.capacity()) {
        ByteBuffer dstTmp = ByteBuffer.allocate(newCapacity);
        flip();
        dstTmp.put(buffer);
        buffer = dstTmp;
      } else {
        buffer.limit(newCapacity);
      }
    }

    /**
     * Drains the buffer to a ByteList, or returns null for an empty buffer
     */
    public ByteList asByteList() {
      flip();
      if (!buffer.hasRemaining()) {
        buffer.clear();
        return null;
      }

      byte[] bss = new byte[buffer.limit()];

      buffer.get(bss);
      buffer.clear();
      return new ByteList(bss, false);
    }

    @Override
    public String toString() { return buffer.toString(); }
  }

  private SSLEngine engine;
  private boolean closed;
  private boolean handshake;
  private MiniSSLBuffer inboundNetData;
  private MiniSSLBuffer outboundAppData;
  private MiniSSLBuffer outboundNetData;

  public MiniSSL(Ruby runtime, RubyClass klass) {
    super(runtime, klass);
  }

  private static Map<String, KeyManagerFactory> keyManagerFactoryMap = new ConcurrentHashMap<String, KeyManagerFactory>();
  private static Map<String, TrustManagerFactory> trustManagerFactoryMap = new ConcurrentHashMap<String, TrustManagerFactory>();

  @JRubyMethod(meta = true)
  public static synchronized IRubyObject server(ThreadContext context, IRubyObject recv, IRubyObject miniSSLContext)
      throws KeyStoreException, IOException, CertificateException, NoSuchAlgorithmException, UnrecoverableKeyException {
    // Create the KeyManagerFactory and TrustManagerFactory for this server
    String keystoreFile = miniSSLContext.callMethod(context, "keystore").convertToString().asJavaString();
    char[] password = miniSSLContext.callMethod(context, "keystore_pass").convertToString().asJavaString().toCharArray();

    KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
    InputStream is = new FileInputStream(keystoreFile);
    try {
      ks.load(is, password);
    } finally {
      is.close();
    }
    KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
    kmf.init(ks, password);
    keyManagerFactoryMap.put(keystoreFile, kmf);

    KeyStore ts = KeyStore.getInstance(KeyStore.getDefaultType());
    is = new FileInputStream(keystoreFile);
    try {
      ts.load(is, password);
    } finally {
      is.close();
    }
    TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
    tmf.init(ts);
    trustManagerFactoryMap.put(keystoreFile, tmf);

    RubyClass klass = (RubyClass) recv;
    return klass.newInstance(context,
        new IRubyObject[] { miniSSLContext },
        Block.NULL_BLOCK);
  }

  @JRubyMethod
  public IRubyObject initialize(ThreadContext threadContext, IRubyObject miniSSLContext)
      throws KeyStoreException, NoSuchAlgorithmException, KeyManagementException {

    String keystoreFile = miniSSLContext.callMethod(threadContext, "keystore").convertToString().asJavaString();
    KeyManagerFactory kmf = keyManagerFactoryMap.get(keystoreFile);
    TrustManagerFactory tmf = trustManagerFactoryMap.get(keystoreFile);
    if(kmf == null || tmf == null) {
      throw new KeyStoreException("Could not find KeyManagerFactory/TrustManagerFactory for keystore: " + keystoreFile);
    }

    SSLContext sslCtx = SSLContext.getInstance("TLS");

    sslCtx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
    closed = false;
    handshake = false;
    engine = sslCtx.createSSLEngine();

    String[] protocols;
    if(miniSSLContext.callMethod(threadContext, "no_tlsv1").isTrue()) {
        protocols = new String[] { "TLSv1.1", "TLSv1.2" };
    } else {
        protocols = new String[] { "TLSv1", "TLSv1.1", "TLSv1.2" };
    }

    if(miniSSLContext.callMethod(threadContext, "no_tlsv1_1").isTrue()) {
        protocols = new String[] { "TLSv1.2" };
    }

    engine.setEnabledProtocols(protocols);
    engine.setUseClientMode(false);

    long verify_mode = miniSSLContext.callMethod(threadContext, "verify_mode").convertToInteger("to_i").getLongValue();
    if ((verify_mode & 0x1) != 0) { // 'peer'
        engine.setWantClientAuth(true);
    }
    if ((verify_mode & 0x2) != 0) { // 'force_peer'
        engine.setNeedClientAuth(true);
    }

    IRubyObject sslCipherListObject = miniSSLContext.callMethod(threadContext, "ssl_cipher_list");
    if (!sslCipherListObject.isNil()) {
      String[] sslCipherList = sslCipherListObject.convertToString().asJavaString().split(",");
      engine.setEnabledCipherSuites(sslCipherList);
    }

    SSLSession session = engine.getSession();
    inboundNetData = new MiniSSLBuffer(session.getPacketBufferSize());
    outboundAppData = new MiniSSLBuffer(session.getApplicationBufferSize());
    outboundAppData.flip();
    outboundNetData = new MiniSSLBuffer(session.getPacketBufferSize());

    return this;
  }

  @JRubyMethod
  public IRubyObject inject(IRubyObject arg) {
    ByteList bytes = arg.convertToString().getByteList();
    inboundNetData.put(bytes.unsafeBytes(), bytes.getBegin(), bytes.getRealSize());
    return this;
  }

  private enum SSLOperation {
    WRAP,
    UNWRAP
  }

  private SSLEngineResult doOp(SSLOperation sslOp, MiniSSLBuffer src, MiniSSLBuffer dst) throws SSLException {
    SSLEngineResult res = null;
    boolean retryOp = true;
    while (retryOp) {
      switch (sslOp) {
        case WRAP:
          res = engine.wrap(src.getRawBuffer(), dst.getRawBuffer());
          break;
        case UNWRAP:
          res = engine.unwrap(src.getRawBuffer(), dst.getRawBuffer());
          break;
        default:
          throw new IllegalStateException("Unknown SSLOperation: " + sslOp);
      }

      switch (res.getStatus()) {
        case BUFFER_OVERFLOW:
          // increase the buffer size to accommodate the overflowing data
          int newSize = Math.max(engine.getSession().getPacketBufferSize(), engine.getSession().getApplicationBufferSize());
          dst.resize(newSize + dst.position());
          // retry the operation
          retryOp = true;
          break;
        case BUFFER_UNDERFLOW:
          // need to wait for more data to come in before we retry
          retryOp = false;
          break;
        case CLOSED:
          closed = true;
          retryOp = false;
          break;
        default:
          // other case is OK.  We're done here.
          retryOp = false;
      }
      if (res.getHandshakeStatus() == HandshakeStatus.FINISHED) {
        handshake = true;
      }
    }

    return res;
  }

  @JRubyMethod
  public IRubyObject read() {
    try {
      inboundNetData.flip();

      if(!inboundNetData.hasRemaining()) {
        return getRuntime().getNil();
      }

      MiniSSLBuffer inboundAppData = new MiniSSLBuffer(engine.getSession().getApplicationBufferSize());
      doOp(SSLOperation.UNWRAP, inboundNetData, inboundAppData);

      HandshakeStatus handshakeStatus = engine.getHandshakeStatus();
      boolean done = false;
      while (!done) {
        SSLEngineResult res;
        switch (handshakeStatus) {
          case NEED_WRAP:
            res = doOp(SSLOperation.WRAP, inboundAppData, outboundNetData);
            handshakeStatus = res.getHandshakeStatus();
            break;
          case NEED_UNWRAP:
            res = doOp(SSLOperation.UNWRAP, inboundNetData, inboundAppData);
            if (res.getStatus() == Status.BUFFER_UNDERFLOW) {
              // need more data before we can shake more hands
              done = true;
            }
            handshakeStatus = res.getHandshakeStatus();
            break;
          case NEED_TASK:
            Runnable runnable;
            while ((runnable = engine.getDelegatedTask()) != null) {
              runnable.run();
            }
            handshakeStatus = engine.getHandshakeStatus();
            break;
          default:
            done = true;
        }
      }

      if (inboundNetData.hasRemaining()) {
        inboundNetData.compact();
      } else {
        inboundNetData.clear();
      }

      ByteList appDataByteList = inboundAppData.asByteList();
      if (appDataByteList == null) {
        return getRuntime().getNil();
      }

      return RubyString.newString(getRuntime(), appDataByteList);
    } catch (SSLException e) {
      RaiseException re = getRuntime().newEOFError(e.getMessage());
      re.initCause(e);
      throw re;
    }
  }

  @JRubyMethod
  public IRubyObject write(IRubyObject arg) {
    byte[] bls = arg.convertToString().getBytes();
    outboundAppData = new MiniSSLBuffer(bls);

    return getRuntime().newFixnum(bls.length);
  }

  @JRubyMethod
  public IRubyObject extract(ThreadContext context) {
    try {
      ByteList dataByteList = outboundNetData.asByteList();
      if (dataByteList != null) {
        return RubyString.newString(context.runtime, dataByteList);
      }

      if (!outboundAppData.hasRemaining()) {
        return context.nil;
      }

      outboundNetData.clear();
      doOp(SSLOperation.WRAP, outboundAppData, outboundNetData);
      dataByteList = outboundNetData.asByteList();
      if (dataByteList == null) {
        return context.nil;
      }

      return RubyString.newString(context.runtime, dataByteList);
    } catch (SSLException e) {
      RaiseException ex = context.runtime.newRuntimeError(e.toString());
      ex.initCause(e);
      throw ex;
    }
  }

  @JRubyMethod
  public IRubyObject peercert() throws CertificateEncodingException {
    try {
      return JavaEmbedUtils.javaToRuby(getRuntime(), engine.getSession().getPeerCertificates()[0].getEncoded());
    } catch (SSLPeerUnverifiedException e) {
      return getRuntime().getNil();
    }
  }

  @JRubyMethod(name = "init?")
  public IRubyObject isInit(ThreadContext context) {
    return handshake ? getRuntime().getFalse() : getRuntime().getTrue();
  }

  @JRubyMethod
  public IRubyObject shutdown() {
    if (closed || engine.isInboundDone() && engine.isOutboundDone()) {
      if (engine.isOutboundDone()) {
        engine.closeOutbound();
      }
      return getRuntime().getTrue();
    } else {
      return getRuntime().getFalse();
    }
  }
}
