import {
  AbsoluteFill,
  Easing,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { MacDesktop } from "./MacDesktop";
import { EndCard } from "./EndCard";

export const HeadroomPromo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  const scene1End = 3 * fps;
  const scene2End = 5.5 * fps;
  const scene3End = 8 * fps;
  const zoomEnd = 10 * fps;

  const showPopover = frame >= scene1End + 8;
  const popoverOpen = spring({
    frame: frame - (scene1End + 8),
    fps,
    config: { damping: 18, stiffness: 180 },
  });

  const zoom = interpolate(frame, [scene3End, zoomEnd], [1, 0.72], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const desktopOpacity = interpolate(frame, [zoomEnd - 10, zoomEnd + 20], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const endOpacity = interpolate(frame, [zoomEnd, zoomEnd + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  const cursorX = interpolate(
    frame,
    [scene1End - 12, scene1End + 6],
    [width * 0.55, width * 0.79],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.bezier(0.4, 0, 0.2, 1),
    },
  );

  const cursorY = interpolate(
    frame,
    [scene1End - 12, scene1End + 6],
    [height * 0.18, height * 0.034],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.bezier(0.4, 0, 0.2, 1),
    },
  );

  const clickScale = frame >= scene1End + 4 && frame <= scene1End + 10 ? 0.86 : 1;

  const sessionPercent = interpolate(frame, [0, scene2End, scene3End], [87, 87, 62], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const weeklyPercent = 74;

  return (
    <AbsoluteFill style={{ backgroundColor: "#050508" }}>
      <AbsoluteFill
        style={{
          transform: `scale(${zoom})`,
          opacity: desktopOpacity,
          transformOrigin: "50% 8%",
        }}
      >
        <MacDesktop
          sessionPercent={sessionPercent}
          weeklyPercent={weeklyPercent}
          popoverProgress={showPopover ? popoverOpen : 0}
        />

        {frame >= scene1End - 12 && frame < zoomEnd && (
          <div
            style={{
              position: "absolute",
              left: cursorX,
              top: cursorY,
              transform: `scale(${clickScale})`,
              pointerEvents: "none",
              zIndex: 50,
            }}
          >
            <MacCursor />
          </div>
        )}
      </AbsoluteFill>

      <AbsoluteFill style={{ opacity: endOpacity }}>
        <EndCard />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const MacCursor: React.FC = () => (
  <svg width="22" height="28" viewBox="0 0 22 28" fill="none">
    <path
      d="M1 1L1 22.5L6.8 17.8L10.5 26.5L13.5 25.2L9.8 16.5L17.5 16.5L1 1Z"
      fill="white"
      stroke="#111"
      strokeWidth="1.2"
    />
  </svg>
);
