
export async function preloadImages(urls) {
  const unique = [...new Set(urls)];
  const entries = await Promise.all(
    unique.map((url) => {
      return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => resolve([url, img]);
        img.onerror = () => reject(new Error(`Failed to load image: ${url}`));
        img.src = url;
      });
    })
  );
  return Object.fromEntries(entries); // { url: HTMLImageElement }
}
