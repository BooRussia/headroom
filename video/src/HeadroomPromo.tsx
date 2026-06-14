import {
  AbsoluteFill,
  Easing,
  interpolate,
  Sequence,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { MacDesktop } from "./MacDesktop";
import { EndCard } from "./EndCard";

export const HeadroomPromo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  const clickStart = 2 * fps;
  const popoverOpenStart = 2.4 * fps;
  const fillStart = 2.8 * fps;
  const fillEnd = 5.8 * fps;
  const closeStart = 6.1 * fps;
  const closeEnd = 7 * fps;
  const holdEnd = 8.2 * fps;
  const fadeStart = holdEnd;
  const fadeEnd = 9.2 * fps;

  const popoverOpenSpring = spring({
    frame: frame - popoverOpenStart,
    fps,
    config: { damping: 20, stiffness: 200 },
  });

  const popoverCloseProgress = interpolate(frame, [closeStart, closeEnd], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.4, 0, 0.2, 1),
  });

  let popoverProgress = 0;
  if (frame >= popoverOpenStart && frame < closeStart) {
    popoverProgress = popoverOpenSpring;
  } else if (frame >= closeStart && frame < closeEnd) {
    popoverProgress = 1 - popoverCloseProgress;
  }

  const sessionPercent = interpolate(frame, [fillStart, fillEnd], [10, 87], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.22, 1, 0.36, 1),
  });

  const menuBarPercent =
    frame < fillStart ? 10 : frame < fillEnd ? sessionPercent : 87;

  const weeklyPercent = 48;

  const heroOpacity = interpolate(frame, [popoverOpenStart, fillStart, closeStart], [1, 0.35, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const desktopOpacity = interpolate(frame, [fadeStart, fadeEnd], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  const blackOverlay = interpolate(frame, [fadeStart, fadeEnd], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  const endOpacity = interpolate(frame, [fadeEnd - 6, fadeEnd + 24], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  const cursorX = interpolate(
    frame,
    [clickStart - 10, clickStart + 8],
    [width * 0.52, width * 0.79],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.bezier(0.4, 0, 0.2, 1),
    },
  );

  const cursorY = interpolate(
    frame,
    [clickStart - 10, clickStart + 8],
    [height * 0.2, height * 0.034],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.bezier(0.4, 0, 0.2, 1),
    },
  );

  const clickScale =
    frame >= clickStart + 2 && frame <= clickStart + 8 ? 0.86 : 1;

  const showCursor = frame >= clickStart - 10 && frame < popoverOpenStart + 20;

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <AbsoluteFill style={{ opacity: desktopOpacity }}>
        <MacDesktop
          sessionPercent={menuBarPercent}
          weeklyPercent={weeklyPercent}
          popoverSessionPercent={sessionPercent}
          popoverProgress={popoverProgress}
          heroOpacity={heroOpacity}
        />

        {showCursor && (
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

      <AbsoluteFill
        style={{
          backgroundColor: "#000",
          opacity: blackOverlay,
        }}
      />

      <AbsoluteFill style={{ opacity: endOpacity }}>
        <Sequence from={Math.round(fadeEnd)} layout="none">
          <EndCard />
        </Sequence>
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
