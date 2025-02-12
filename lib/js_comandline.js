(function () {
    let img = document.querySelector("div.page-chapter img");
    if (!img) return '';

    let newImg = new Image();
    newImg.crossOrigin = "anonymous"; // Kích hoạt CORS
    newImg.src = img.src;

    newImg.onload = function () {
        let canvas = document.createElement('canvas');
        let ctx = canvas.getContext('2d');
        canvas.width = newImg.naturalWidth;
        canvas.height = newImg.naturalHeight;

        ctx.drawImage(newImg, 0, 0);
        let dataUrl = canvas.toDataURL('image/png');
        console.log(dataUrl);
    };

    newImg.onerror = function () {
        console.log("Không thể tải ảnh với CORS.");
    };
})();





//lazyload image
const imageUrls = [...document.querySelectorAll('img')].map(img => img.dataset.src || img.src);
console.log(imageUrls);



//Base64 => byte (Base64Encode())
