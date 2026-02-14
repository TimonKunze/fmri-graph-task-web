/*Rotate points around a center point in 2D. Angle in radians.*/
export function rotatePoint(center, point, angle) {
    // Calculate distance from center to point
    let dx = point[0] - center[0];
    let dy = point[1] - center[1];

    // Calculate new coordinates
    let newX = center[0] + dx * Math.cos(angle) - dy * Math.sin(angle);
    let newY = center[1] + dx * Math.sin(angle) + dy * Math.cos(angle);

    return [newX, newY];
}

/*Calculate horizontal angle from given points line segment.*/
export function getHorAngleFromLineSeg(p1, p2) {
  let dx = p1[0] - p2[0];
  let dy = p1[1] - p2[1];
  let angle = Math.atan(dy / dx); //* 180 / PI;

  return angle;
}


export function getRelations(matrix, value=1, excludeSelfRel=false) {
  let relations = [];
  for (let i=0; i<matrix.length; i++) {
    for (let j = 0; j < matrix[i].length; j++) {
      if (matrix[i][j] === value) {
        if (excludeSelfRel) {
          if (i!==j) {
          relations.push([i, j]);
          }
        } else {
          relations.push([i, j]);
        }
      }
    } 
  }
  return relations;
}


/* Get a point on the line between two other points. */
export function point_on_line(point1, point2, t) {
    const x = point1[0] + t * (point2[0] - point1[0]);
    const y = point1[1] + t * (point2[1] - point1[1]);
    return [x, y];
}

/* Get 4 equidistant points. */
export function getEquidistantPoints(point1, point2, distance) {
    // Calculate midpoint
    const midpoint = [(point1[0] + point2[0]) / 2, (point1[1] + point2[1]) / 2];
    // Calculate direction vector
    const vector = [point2[0] - point1[0], point2[1] - point1[1]];
    const length = Math.sqrt(vector[0] ** 2 + vector[1] ** 2);
    const direction = [vector[0] / length, vector[1] / length];
    // Calculate equidistant points
    const equidistantPoints = [
        [midpoint[0] + distance * direction[0], midpoint[1] + distance * direction[1]],
        [midpoint[0] - distance * direction[0], midpoint[1] - distance * direction[1]],
        [midpoint[0] + distance * direction[1], midpoint[1] - distance * direction[0]],
        [midpoint[0] - distance * direction[1], midpoint[1] + distance * direction[0]]
    ];
    return equidistantPoints;
}
