// utils/imageCache.js

let IMG_CACHE = {};

export function setImageCache(cache) {
  IMG_CACHE = cache;
}

export function getImage(url) {
  return IMG_CACHE[url];
}
