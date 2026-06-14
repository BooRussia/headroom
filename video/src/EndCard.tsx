import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleIn = spring({ frame, fps, config: { damping: 200 } });
  const subtitleIn = spring({ frame: frame - 8, fps, config: { damping: 200 } });
  const ctaIn = spring({ frame: frame - 18, fps, config: { damping: 16, stiffness: 120 } });

  const pulse = interpolate(frame % 60, [0, 30, 60], [1, 1.04, 1]);

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        background:
          "radial-gradient(circle at 50% 35%, rgba(99,102,241,0.22), transparent 42%), linear-gradient(180deg, #09090f, #050508)",
        color: "white",
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
        textAlign: "center",
        padding: 40,
      }}
    >
      <div
        style={{
          opacity: titleIn,
          transform: `translateY(${interpolate(titleIn, [0, 1], [24, 0])}px)`,
          fontSize: 92,
          fontWeight: 800,
          letterSpacing: -3,
          background: "linear-gradient(135deg, #fff 0%, #c7d2fe 55%, #86efac 100%)",
          WebkitBackgroundClip: "text",
          color: "transparent",
        }}
      >
        Headroom
      </div>

      <div
        style={{
          opacity: subtitleIn,
          transform: `translateY(${interpolate(subtitleIn, [0, 1], [16, 0])}px)`,
          marginTop: 10,
          fontSize: 28,
          color: "rgba(255,255,255,0.72)",
          maxWidth: 760,
          lineHeight: 1.35,
        }}
      >
        Know your Claude limits before you hit them
      </div>

      <div
        style={{
          opacity: subtitleIn,
          marginTop: 8,
          fontSize: 16,
          color: "rgba(255,255,255,0.42)",
        }}
      >
        5-hour window · weekly caps · exact reset times · Mac notifications
      </div>

      <div
        style={{
          opacity: ctaIn,
          transform: `scale(${ctaIn * pulse})`,
          marginTop: 42,
          padding: "16px 34px",
          borderRadius: 999,
          background: "linear-gradient(135deg, #6366f1, #22c55e)",
          fontSize: 24,
          fontWeight: 700,
          boxShadow: "0 18px 50px rgba(99,102,241,0.35)",
        }}
      >
        Download for Free
      </div>

      <div
        style={{
          opacity: ctaIn * 0.8,
          marginTop: 18,
          fontSize: 14,
          color: "rgba(255,255,255,0.38)",
        }}
      >
        Free · Open source · macOS menu bar app
      </div>
    </div>
  );
};
