module ProjectileTrajectory
    ( drawProjectile
    ) where

import Data.HashMap.Strict (fromList)
import Drawing (Color (..), blankCanvas, setPixelMap)
import Drawing.Output (canvasToPpm)
import Space (Point (..), Vector (..), addVectorP, addVectorV, normalize, multiplyVector)

data Projectile = Projectile { getPosition :: Point, _getVelocity :: Vector }
data Environment = Environment Vector Vector

tick :: Environment -> Projectile -> Projectile
tick (Environment gravity wind) (Projectile position velocity) =
    let position' = position `addVectorP` velocity
        velocity' = velocity `addVectorV` gravity `addVectorV` wind
    in Projectile position' velocity'

drawProjectile :: IO ()
drawProjectile = do
    let width = 900
        height = 300
        start = Point 0 1 0
        velocity = normalize (Vector 1 1.1 0) `multiplyVector` 10
        pStart = Projectile start velocity
        gravity = Vector 0 (-0.1) 0
        wind = Vector (-0.01) 0 0
        env = Environment gravity wind
        canvas = blankCanvas width height
        projectileTrajectory = scanl (flip tick) pStart (repeat env)
        insideCanvasPositions =
            takeWhile (\p -> (getPointY . getPosition $ p) > 0) projectileTrajectory
        red = Color 1 0 0
        positionToCanvasTuple p = 
            let canvasX = round . getPointX . getPosition $ p
                canvasY = height - (round . getPointY . getPosition $ p)
            in ((canvasX, canvasY), red)
        pixelMap = fromList $ map positionToCanvasTuple insideCanvasPositions
        canvas' = setPixelMap canvas pixelMap
    putStr . canvasToPpm $ canvas'
