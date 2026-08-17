# Erasmus photo gallery

Drop your Stavanger exchange photos in this folder, then edit the `erasmusPhotos`
array at the bottom of `international-mobility.html` to match:

```js
const erasmusPhotos = [
    { src: 'erasmus-photos/photo-1.jpg', caption: 'Stavanger, Norway' },
    { src: 'erasmus-photos/your-photo.jpg', caption: 'Your caption here' },
];
```

Each entry becomes one slide in the carousel. Until a file exists, its slide
shows a placeholder instead of a broken image.
