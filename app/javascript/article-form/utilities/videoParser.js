/**
 * Parses YouTube URLs and returns embed URLs
 * Supports:
 * - youtube.com/watch?v=VIDEO_ID
 * - youtu.be/VIDEO_ID
 * - youtube.com/embed/VIDEO_ID
 * - youtube.com/v/VIDEO_ID
 */
function parseYouTubeUrl(url) {
  if (!url || !url.trim()) {
    return null;
  }

  try {
    const urlObj = new URL(url.trim());
    const host = urlObj.hostname.toLowerCase().replace(/^www\./, '');

    // Check if it's a YouTube URL
    if (!host.match(/^(?:youtu\.be|youtube\.com)$/)) {
      return null;
    }

    let videoId = null;

    if (host === 'youtu.be') {
      // youtu.be/VIDEO_ID
      videoId = urlObj.pathname.split('/').filter(Boolean)[0];
    } else if (host === 'youtube.com') {
      // Check query params first (youtube.com/watch?v=VIDEO_ID)
      const params = new URLSearchParams(urlObj.search);
      videoId = params.get('v');

      // Check path (youtube.com/embed/VIDEO_ID or youtube.com/v/VIDEO_ID)
      if (!videoId) {
        const pathSegments = urlObj.pathname.split('/').filter(Boolean);
        const embedIndex = pathSegments.indexOf('embed');
        const vIndex = pathSegments.indexOf('v');
        const index = embedIndex !== -1 ? embedIndex : vIndex;
        if (index !== -1 && pathSegments[index + 1]) {
          videoId = pathSegments[index + 1];
        }
      }
    }

    return videoId ? `https://www.youtube.com/embed/${videoId}` : null;
  } catch (e) {
    return null;
  }
}

/**
 * Parses Mux URLs and returns embed URLs
 * Supports:
 * - player.mux.com/VIDEO_ID
 * - player.mux.com/VIDEO_ID?params
 */
function parseMuxUrl(url) {
  if (!url || !url.trim()) {
    return null;
  }

  try {
    const urlObj = new URL(url.trim());
    const host = urlObj.hostname.toLowerCase();

    // Check if it's a Mux URL
    if (host !== 'player.mux.com') {
      return null;
    }

    // Extract video ID from path
    const path = urlObj.pathname;
    if (!path || path === '/') {
      return null;
    }

    // Remove leading slash and query params
    const videoId = path.replace(/^\//, '').split('?')[0];
    return videoId ? `https://player.mux.com/${videoId}` : null;
  } catch (e) {
    return null;
  }
}

/**
 * Parses Twitch URLs and returns embed URLs
 * Supports:
 * - www.twitch.tv/videos/VIDEO_ID
 * - player.twitch.tv/?video=VIDEO_ID
 */
function parseTwitchUrl(url) {
  if (!url || !url.trim()) {
    return null;
  }

  try {
    const urlObj = new URL(url.trim());
    const host = urlObj.hostname.toLowerCase().replace(/^www\./, '');

    // Check if it's a Twitch URL
    if (!host.match(/^(?:player\.)?twitch\.tv$/)) {
      return null;
    }

    let videoId = null;

    if (host === 'player.twitch.tv') {
      // player.twitch.tv/?video=VIDEO_ID
      const params = new URLSearchParams(urlObj.search);
      videoId = params.get('video');
    } else if (host === 'twitch.tv') {
      // www.twitch.tv/videos/VIDEO_ID
      const path = urlObj.pathname;
      const videosMatch = path.match(/^\/videos\/(\d+)/);
      if (videosMatch) {
        videoId = videosMatch[1];
      }
    }

    if (!videoId) {
      return null;
    }

    // Twitch requires a parent parameter for security. Use current hostname.
    const parentDomain = typeof window !== 'undefined' 
      ? window.location.hostname 
      : 'localhost';
    
    return {
      embedUrl: `https://player.twitch.tv/?video=${videoId}&parent=${parentDomain}&autoplay=false`,
      videoId,
    };
  } catch (e) {
    return null;
  }
}

/**
 * Parses a video URL and returns the embed URL and type
 * @param {string} url - The video URL (YouTube, Mux, or Twitch)
 * @returns {Object|null} - { embedUrl: string, type: 'youtube' | 'mux' | 'twitch', videoId: string } or null
 */
export function parseVideoUrl(url) {
  if (!url || !url.trim()) {
    return null;
  }

  // Try YouTube first
  const youtubeEmbed = parseYouTubeUrl(url);
  if (youtubeEmbed) {
    const videoId = youtubeEmbed.split('/embed/')[1];
    return {
      embedUrl: youtubeEmbed,
      type: 'youtube',
      videoId,
    };
  }

  // Try Mux
  const muxEmbed = parseMuxUrl(url);
  if (muxEmbed) {
    const videoId = muxEmbed.split('player.mux.com/')[1];
    return {
      embedUrl: muxEmbed,
      type: 'mux',
      videoId,
    };
  }

  // Try Twitch
  const twitchResult = parseTwitchUrl(url);
  if (twitchResult) {
    return {
      embedUrl: twitchResult.embedUrl,
      type: 'twitch',
      videoId: twitchResult.videoId,
    };
  }

  return null;
}

/**
 * Gets thumbnail URL for a video
 * @param {Object} videoInfo - The result from parseVideoUrl
 * @returns {string|null} - Thumbnail URL or null
 */
export function getVideoThumbnail(videoInfo) {
  if (!videoInfo) {
    return null;
  }

  if (videoInfo.type === 'youtube') {
    return `https://img.youtube.com/vi/${videoInfo.videoId}/maxresdefault.jpg`;
  }

  if (videoInfo.type === 'mux' && videoInfo.videoId) {
    return `https://image.mux.com/${videoInfo.videoId}/thumbnail.webp`;
  }

  return null;
}

