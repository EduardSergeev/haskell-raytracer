module ProjectileTrajectory
    ( drawProjectile
    ) where

import Data.HashMap.Strict (fromList)
import Drawing (Color (..), canvas, setPixelMap)
import Drawing.Output (canvasToPpm)
import Space (Point (..), Vector (..), addVectorP, addVectorV, normalize, multiplyVector)

data Projectile = Projectile { position :: Point,  velocity :: Vector }
data Environment = Environment Vector Vector

tick :: Environment -> Projectile -> Projectile
tick (Environment gravity wind) (Projectile position velocity) =
    let position' = position `addVectorP` velocity
        velocity' = velocity `addVectorV` gravity `addVectorV` wind
    in Projectile position' velocity'

drawProjectile :: IO ()
drawProjectile = do
    let start = Point 0 1 0
        velocity = normalize (Vector 1 1.1 0) `multiplyVector` 10
        pStart = Projectile start velocity
        gravity = Vector 0 (-0.1) 0
        wind = Vector (-0.01) 0 0
        env = Environment gravity wind
        width = 900
        height = 300
        c = canvas 900 300
        projectileTrajectory = scanl (flip tick) pStart (repeat env)
        insideCanvasPositions =
            takeWhile (\p -> (pointY . position $ p) > 0) projectileTrajectory
        red = Color 1 0 0
        positionToCanvasTuple p = 
            let canvasX = round . pointX . position $ p
                canvasY = 300 - (round . pointY . position $ p)
            in ((canvasX, canvasY), red)
        pixelMap = fromList $ map positionToCanvasTuple insideCanvasPositions
        c' = setPixelMap pixelMap c
    putStr . canvasToPpm $ c'
