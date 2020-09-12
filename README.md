# The Ray Tracer Challenge With Haskell

Writing the first Haskell application by walking through The Ray Tracer Challenge book.

[![Build](../../workflows/Build/badge.svg)](../../actions?query=workflow%3ABuild+branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/github/EduardSergeev/haskell-raytracer/badge.svg?branch=master)](https://coveralls.io/github/EduardSergeev/haskell-raytracer?branch=master)

## Chapters 1-4

### Changes

* Basic 3D space primitives (Point, Vector) and operations on them.
* 2D canvas with functions to set its pixels and output it as a valid PPM string.
* Matrices with main operations `multiply (|*|)` and `inverse`, and a bunch of others.
* 3D transformations using 4x4 matrices.
* A couple of usage examples: drawing projectile trajectory and drawing clock face.

### Thoughts

`Space` module feels clunky. I implemented `Point` and `Vector` as data types instead of proposed in the book tuples or lists. As a result, there are too many specialized functions which so far are not used anywhere outside the module's test suite and projectile example. Cannot tell how heavily this module will be used further down the line. It might make sense to implement the primitives as matrices constructed from corresponding functions.

*([Edit]: The `Space` module is already used heavily in the next chapter)*

`Canvas` `setPixel` performance is a bit of a concern. Setting a large number of pixels even on a moderately sized canvas one-by-one will be inefficient. In the projectile example I used a `HashMap` of pixels and `map` to set pixels in one pass. In the future it will probably be better to just construct the canvas from a pre-built set of pixels.

`Matrix` module looks okay-ish. Glanced into the monads world when decided that `multiply` and `inverse` operations must return `Either`. As a result, testing got more interesting as I had to use `do` notation or `>>=` when applying transformations. I do not think what I am doing with them currently is idiomatic, will try to improve it along the way.

Nothing special in the `Transform` module although chaining transformations which can fail was interesting. Same as the above, I will most likely revisit it later.

### Image Samples

[Using canvas PPM output (converted to PNG) with points and vectors.](/samples/projectile.png)

[Using transformations to place points at clock face hours positions.](/samples/clock.png)

## Chapter 5

### Changes

* Data types for Sphere, Ray and Intersection.
* Operations to find an intersection and a hit (first intersection) of a ray with a sphere.

### Thoughts

Among the new modules `Geometry`, `Geometry.Sphere` and `Ray` the first one turned out to be the trickiest. I wanted to make `Intersection a` and instance of `Ord` typeclass and for that I had to add `Eq` constraint to the `Intersection`'s type parameter. Apparently, you cannot do this in a simple data type declaration. The solution that I found [here](https://wiki.haskell.org/Data_declaration_with_constraint) suggests using GADTs for this and so I did.

*[Edit] As it was pointed out to me, I don't need the type parameter constraint here. Moreover, it is generally a bad idea to add such constraints, according to [this explanation](https://www.google.com/url?q=https://stackoverflow.com/a/12770425/394253&sa=D&source=hangouts&ust=1598983884505000&usg=AFQjCNHjctWqcZl4E-UgSEJlA9lu-ETcLQ). In addition to that, I only needed these constraints so that I could use `minimum` instead `minimumBy`. Currently, it makes more sense to use `minimumBy` instead of implementing `Ord`. I don't really have a requirement to always sort intersections by distance while completely ignoring the object. It might come later though.*

When I got to implementing this chapter's practical example, I decided that I want to refactor matrix transformations to avoid working with `Either`. An experienced Haskell developer showed me an example of using `TypeLits` (`TypeNats` for my case) which I could use to check matrices' sizes at compile time instead of runtime. That was the most difficult part.

I am pretty far from understanding what exactly is happening there but hey, it works! Initially, I have spent quite some time trying to magically pass data constructor parameters to type parameters and wondered why I couldn't make it work. Now, my understanding is that a big chunk of the type-safety with `TypeLits` and the related features is achieved with good reasoning and encapsulation. That is, you "inform" compiler what type you are returning from which function (`TypeOperators` are really cool though). You also have to hide data constructors and get you type's instances from functions with fully described types. If you get any of it wrong, the compiler cannot help you if some arbitrary type instances start flying around.

For the sample, instead of doing it the way suggested by the hints I used a kind of a brute-force approach. First, applied scale and translation transformations to make the sphere a proper size and put it in the centre of the canvas. Then, cast a ray perpendicular to the canvas from each pixel's `x` and `y` coordinates and a suitable `z` coordinate. The resulting hits draw a silhouette of the given sphere. 

### Image Samples

[Using ray intersections to draw a silhouette of a sphere on the canvas.](/samples/silhouette.png)

## Chapter 6

### Changes

* Sphere normals calculation.
* Data types for material and point light.
* Perceived sphere points color computation using material and lighting.

### Thoughts

Overall, nothing too complex in terms of programming this chapter, although the result feels really satisfying. The biggest change was removing more of the `Either`'s from the code. My reasoning is that currently I don't have situations when I really need my code to fail gracefully and follow some other path. If something goes wrong, e.g. trying to invert an uninvertible matrix or create a point not from 4x1 matrix, I just want an exception. I might revisit this later when I have a full picture of the code flow and learn to write proper monadic functions.

Following an advice, added `-Wall` option for the compiler. This lead to improving code by cleaning up quite a few places which compiler marked with warnings.

A `let`-ladder in the `Materials.lighting` function is a little concerning. I don't have a good idea on how to improve it yet.

As expected, I had to rewrite the previous chapter sample's code to properly cast rays from a single view point. While doing it the old way (by casting rays perpendicular to the canvas) produced a fair-looking 3D image, it had some lighting artifacts on the sphere.

### Image Samples

[Using material and lighting to render a first real sphere.](/samples/sphere-with-lighting.png)

## Chapter 7

### Changes

* World data type holding objects and a single light.
* Ray intersection with World.
* Camera data type and view transform.
* Render function combining Camera, World and view transform to produce an image.

### Thoughts

Pretty straightforward implementation overall. The biggest change was probably doing some refactoring to move around and rename modules holding intersection data types and logic. Finally figured out the record update syntax such as `record' = record { getValue = newValue }`, for some reason I have failed to discover it earlier. Anyway, started to get rid of some of the `setValue` functions that I started adding previously.

All the ray intersection functions and `World` still work with the single type of object - `Sphere`. Cannot tell which way the book will turn with this so leaving generalization for later.

### Image Samples

[Using a camera with a view transform to render a world with 3 spheres and walls.](/samples/camera-world-render.png)

## Chapter 8

### Changes

* Detection of a point being in the shadow.
* Computation of the color of a shadowed point.

### Thoughts

Two relatively small features and a handful of tests, nothing special. The interesting part came when trying to render the previous chapter's sample with shadows functionality in place.

Firstly, in my render output I got "acne" (black dots) on some of the walls. The book specifically mentions this effect but it should affect the whole picture when it happens, not some specific objects. Moreover, the author gives a solution to avoid this which I also implemented. Quick googling led me to the [book's forums](https://forum.raytracerchallenge.com/thread/57/shadows-point-epsilon-00001-causes) with the solution. I made a mistake by using single precision floating point numbers (`Float`) for calculations, `Double` is the way to go. Easy fix with find and replace, problem solved. And I also had to adjust one of the tests which I previously fine-tuned because it wasn't matching the book. I should have digged deeper into the issue that time.

The second thing that I wanted to look into was the rendering performance. The author warns in one of the recent chapters that by this point the ray tracer becomes pretty heavy. It is left to the reader's discretion to try, for example, implementing a world with multiple lights and said that they should expect the rendering to be pretty slow. Despite this, I figured that it was a good opportunity to try doing some optimization work and maybe try out Haskell's concurrency. It definitely felt like a good case for concurrent work as the rendering is performed by computing colors of a huge number of individual pixels independent of each other.

The results were not what I excepted. Adding parallelism to the computations (which, by the way, was rather easy for my purpose) actually lead to performance degradation. The application performed better on a single thread than on multiple. It was time for profiling. Setting it up also was a matter of passing a couple of flags to the `run` command. The result showed that the `submatrix` function and, specifically, the list comprehension inside it, were the hotspots. Is allocation of new lists a bottleneck here? Long story short, I refactored the `inverse` function to make in-place calculations. Previously it was done with mutually recursive calls to `determinant`, `cofactor` and `minor`, which together used `submatrix` very heavily.

The resulting improvement was, again, unexpected although this time in a pleasant way. The render times dropped drastically (on a quad-core i7-8565U laptop processor):
* `320x240` image - from ~3 minutes to **4-5 seconds**.
* `640x480` image - from ~7.5 minutes to **10-15 seconds**.

The only deduction that I can make from this is that concurrency doesn't help if the bottleneck is memory allocation and, I suppose, garbage collection. In hindsight the resulting improvement makes sense. In order to compute a 4x4 matrix's determinant employing submatrix extraction we need to create 64 matrices (counting 24 empty lists for the base case of the recursion). Multiplying it by the number of pixels in a `640x480` image gives the result of close to 20 million lists being allocated. This is with the assumption that we only call `determinant` once per pixel. In my highly inefficient implementation there was also an `invertible` check which called `determinant` separately, as well as 16 calls to `cofactor` to compute the resulting inverted matrix. That is *a lot* of lists. Wonder why it was so slow?

The important point here is that the performance problem I encountered should also be present in solutions using other popular languages with garbage collection. To improve this it makes sense to implement inverse matrix computation in place, even if it leads to a quite repetitive and ugly code. Interestingly, this implementation might actually yield to optimization by parallelism. I will give it another try when performance starts to bother me again.

### Image Samples

[Using a point-in-shadow detection and shadowed point color calculation to render the same scene.](/samples/render-with-shadows.png)

## Chapter 9

### Changes

* Introduction of a general `Shape` data type in place of `Sphere` and refactoring of existing functionality.
* Implementation of the `Plane` shape type.

### Thoughts

Finally! Now there is a basic abstraction for shapes that we render. It's hard for me to tell what would be the best approach here. After doing some reading I stopped on implementing shapes as a simple ADT with `ShapeType` as a first data constructor parameter. This way I can use functions to construct shapes with required type, and pattern match against this parameter when I need to distinguish between shapes. The only downside is that I had to merge together three modules because of circular dependencies that I was getting. I will see how I can improve it along the way.

### Image Samples

[Using planes to render a hexagonal room around the three spheres.](/samples/hexagonal-room.png)
