import "./index.css";
import { Composition } from "remotion";
import { HeadroomPromo } from "./HeadroomPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="HeadroomPromo"
        component={HeadroomPromo}
        durationInFrames={360}
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
