# Floating Jelly

A standalone, entirely code-drawn interpretation of the supplied Jelly artwork. Open `index.html` directly in a browser; no server, build step, packages, image files, external fonts, base64, or network requests are required.

The illustration uses editable SVG Bézier paths, layered gradients, translucent highlights, and blurred rim lighting. It recreates the reference's silhouette and palette by hand; it is not a pixel-identical reconstruction of the rendered image. The artwork is in the original 1254 × 1254 coordinate space. The four overlapping groups are drawn back to front: tail, lower fold, middle fold, and bell.

`animation.js` applies a slow rise and fall, gentle bell compression, and delayed movement through the lower folds and tail. Pause freezes the current frame; Original pose removes every animation transform. Motion adjusts speed. Reduced-motion preferences start with the original pose, and animation suspends while the page is hidden.

To embed it, copy the SVG and animation into a page, keeping the gradient and shape IDs unique if more than one instance is used. The page's controls can be restyled in `style.css`.
