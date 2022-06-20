---
sidebar_position: 4
title: Point Set Distribution
---

:::danger
These functions aren't yet implemented with these specific names. This should be changed soon
:::

Point set distributions are one of the three distribution formats. They are stored as a list of x-y coordinates representing both discrete and continuous distributions.

One complication is that it's possible to represent invalid probability distributions in the point set format. For example, you can represent shapes with negative values, or shapes that are not normalized.

### make

Converts the distribution in question into a point set distribution. If the distribution is symbolic, then it does this by taking the quantiles. If the distribution is a sample set, then it uses a version of kernel density estimation to approximate the point set format. One complication of this latter process is that if there is a high proportion of overlapping samples (samples that are exactly the same as each other), it will convert these samples into discrete point masses. Eventually we'd like to add further methods to help adjust this process.

```
PointSet.make: (distribution) => pointSetDist
```

### makeContinuous

**TODO: Now called "toContinuousPointSet"**

Converts a set of x-y coordinates directly into a continuous distribution.

```
PointSet.makeContinuous: (list<{x: number, y: number}>) => pointSetDist
```

```javascript
PointSet.makeContinuous([
  { x: 0, y: 0.1 },
  { x: 1, y: 0.2 },
  { x: 2, y: 0.15 },
  { x: 3, y: 0.1 },
]);
```

### makeDiscrete

**TODO: Now called "toDiscretePointSet"**

Converts a set of x-y coordinates directly into a discrete distribution.

```
PointSet.makeDiscrete: (list<{x: number, y: number}>) => pointSetDist
```

```javascript
PointSet.makeDiscrete([
  { x: 0, y: 0.1 },
  { x: 1, y: 0.2 },
  { x: 2, y: 0.15 },
  { x: 3, y: 0.1 },
]);
```