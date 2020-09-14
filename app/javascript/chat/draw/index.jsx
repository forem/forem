import { h } from 'preact';
import { useRef, useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

function Draw({ sendCanvasImage }) {
  const canvasRef = useRef(null);
  const palettes = [
    '#F4908E',
    '#F2F097',
    '#88B0DC',
    '#F7B5D1',
    '#53C4AF',
    '#FDE38C',
  ];
  const [isDrawing, setIsDrawing] = useState(false);
  const [drawColor, setDrawColor] = useState('#F58F8E');
  const [coordinates, setCoordinates] = useState({});
  const [sendButtonDisabled, setSendButtonDisabled] = useState(true);
  const prevCoordinates = usePrevious(coordinates);

  const handleCanvasSend = () => {
    const canvas = canvasRef.current;
    canvas.toBlob((blob) => {
      sendCanvasImage(new File([blob], 'draw.png'));
    });
  };
  const handleMouseDown = (e) => {
    setCoordinates({ x: e.offsetX, y: e.offsetY });
    setIsDrawing(true);
  };
  const handleImageDrop = (e) => {
    e.preventDefault();
    if (!canvasRef.current) {
      return;
    }
    const canvas = canvasRef.current;
    const context = canvas.getContext('2d');
    canvas.classList.remove('opacity-25');

    const { files } = e.dataTransfer;
    const img = new Image();
    img.src = URL.createObjectURL(files[0]);

    img.onload = () => {
      const scale = Math.min(
        canvas.width / img.width,
        canvas.height / img.height,
      );
      const x = canvas.width / 2 - (img.width / 2) * scale;
      const y = canvas.height / 2 - (img.height / 2) * scale;
      context.drawImage(img, x, y, img.width * scale, img.height * scale);
    };
  };

  const handleClearCanvas = () => {
    setSendButtonDisabled(true);
    if (!canvasRef.current) {
      return;
    }
    const context = canvasRef.current.getContext('2d');
    context.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
  };

  const handleDragHover = (e) => {
    e.preventDefault();

    canvasRef.current.classList.add('opacity-25');
  };
  const handleChangeColor = (e) => {
    setDrawColor(e.target.style.backgroundColor);
  };
  const handleDragExit = (e) => {
    e.preventDefault();
    canvasRef.current.classList.remove('opacity-25');
    canvasRef.current.classList.add('opacity-100');
  };
  const handleMouseMove = (e) => {
    if (isDrawing) {
      setSendButtonDisabled(false);
      setCoordinates({ x: e.offsetX, y: e.offsetY });
    }
  };
  const handleMouseUp = () => {
    setCoordinates({});
    setIsDrawing(false);
  };

  useEffect(() => {
    if (!canvasRef.current) {
      return;
    }
    const context = canvasRef.current.getContext('2d');
    if (isDrawing) {
      context.beginPath();
      context.strokeStyle = drawColor;
      context.lineWidth = 2;
      context.moveTo(prevCoordinates.x, prevCoordinates.y);
      context.lineTo(coordinates.x, coordinates.y);
      context.stroke();
      context.closePath();
    }
  }, [drawColor, isDrawing, coordinates, prevCoordinates]);

  return (
    <div className="p-4 grid gap-2 crayons-card mb-4 connect-draw">
      <div className="mb-1 draw-title">
        <h2>Connect Draw</h2>
        <div className="colors" style="pointer-events: all;">
          {palettes.map((color) => (
            <button
              className="color"
              onClick={handleChangeColor}
              style={`background-color: ${color}`}
              title={`color-${color}`}
            />
          ))}
        </div>
      </div>
      <div aria-hidden className="drawArea" onMouseUp={handleMouseUp}>
        <canvas
          className="drawConnect"
          ref={canvasRef}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onDrop={handleImageDrop}
          onDragOver={handleDragHover}
          onDragExit={handleDragExit}
          height="600"
        />
        <div className="drawActions">
          <Button
            className=" crayons-btn crayons-btn--secondary"
            onClick={handleClearCanvas}
            title="clear"
            type="button"
            size="s"
            variant="secondary"
          >
            Clear
          </Button>
          <Button
            className="crayons-btn"
            onClick={handleCanvasSend}
            title="send"
            disabled={sendButtonDisabled}
          >
            Send
          </Button>
        </div>
      </div>
    </div>
  );
}

function usePrevious(value) {
  const ref = useRef();
  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref.current;
}
Draw.propTypes = {
  sendCanvasImage: PropTypes.func,
};

export default Draw;
