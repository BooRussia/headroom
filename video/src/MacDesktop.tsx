import { interpolate, useCurrentFrame } from "remotion";
import { MenuBarPopover } from "./MenuBarPopover";

type MacDesktopProps = {
  sessionPercent: number;
  weeklyPercent: number;
  popoverProgress: number;
};

export const MacDesktop: React.FC<MacDesktopProps> = ({
  sessionPercent,
  weeklyPercent,
  popoverProgress,
}) => {
  const frame = useCurrentFrame();
  const glow = interpolate(frame % 45, [0, 22, 45], [0.35, 0.9, 0.35]);

  const statusColor =
    sessionPercent >= 90
      ? "#ff5f57"
      : sessionPercent >= 75
        ? "#ff9f0a"
        : sessionPercent >= 50
          ? "#ffd60a"
          : "#30d158";

  const dot =
    sessionPercent >= 90
      ? "🔴"
      : sessionPercent >= 75
        ? "🟠"
        : sessionPercent >= 50
          ? "🟡"
          : "🟢";

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background:
          "linear-gradient(180deg, #1a1a22 0%, #0d0d12 28%, #12121a 100%)",
        position: "relative",
        overflow: "hidden",
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          background:
            "radial-gradient(circle at 70% 20%, rgba(99,102,241,0.18), transparent 35%), radial-gradient(circle at 20% 80%, rgba(16,185,129,0.12), transparent 30%)",
        }}
      />

      <div
        style={{
          height: 34,
          background: "rgba(18,18,22,0.82)",
          backdropFilter: "blur(24px)",
          borderBottom: "1px solid rgba(255,255,255,0.06)",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 18px",
          color: "rgba(255,255,255,0.88)",
          fontSize: 13,
          position: "relative",
          zIndex: 20,
        }}
      >
        <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
          <span style={{ fontWeight: 600 }}>Finder</span>
          <span style={{ opacity: 0.55 }}>File</span>
          <span style={{ opacity: 0.55 }}>Edit</span>
        </div>

        <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
          <span style={{ opacity: 0.55 }}>Wi-Fi</span>
          <span style={{ opacity: 0.55 }}>Mon Jun 14  2:41 PM</span>
          <div
            style={{
              padding: "3px 10px",
              borderRadius: 6,
              background: "rgba(255,255,255,0.08)",
              boxShadow: `0 0 0 1px rgba(255,255,255,0.08), 0 0 18px ${statusColor}${Math.round(glow * 99)
                .toString(16)
                .padStart(2, "0")}`,
              fontWeight: 600,
              fontVariantNumeric: "tabular-nums",
            }}
          >
            {dot} {Math.round(sessionPercent)}%
          </div>
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          top: 90,
          left: "50%",
          transform: "translateX(-50%)",
          color: "rgba(255,255,255,0.92)",
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: 56, fontWeight: 700, letterSpacing: -1.5 }}>
          Your desktop. Your limits.
        </div>
        <div
          style={{
            marginTop: 12,
            fontSize: 22,
            color: "rgba(255,255,255,0.55)",
          }}
        >
          Always visible in the menu bar
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          right: 28,
          top: 40,
          zIndex: 30,
          transform: `translateY(${interpolate(popoverProgress, [0, 1], [-8, 0])}px)`,
          opacity: popoverProgress,
        }}
      >
        <MenuBarPopover
          sessionPercent={sessionPercent}
          weeklyPercent={weeklyPercent}
          progress={popoverProgress}
        />
      </div>

      <div
        style={{
          position: "absolute",
          bottom: 28,
          left: 28,
          width: 84,
          height: 84,
          borderRadius: 20,
          background: "rgba(255,255,255,0.06)",
          border: "1px solid rgba(255,255,255,0.08)",
          display: "grid",
          placeItems: "center",
          color: "rgba(255,255,255,0.35)",
          fontSize: 12,
        }}
      >
        App
      </div>
    </div>
  );
};
