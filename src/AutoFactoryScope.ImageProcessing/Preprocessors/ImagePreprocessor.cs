using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace AutoFactoryScope.ImageProcessing.Preprocessors;

public interface IImagePreprocessor
{
    byte[] Preprocess(string imagePath, int targetSize = 640, bool keepAspect = true);
}

public sealed class ImagePreprocessor : IImagePreprocessor
{
    public byte[] Preprocess(string imagePath, int targetSize = 640, bool keepAspect = true)
    {
        if (File.Exists(imagePath) is false) throw new FileNotFoundException(imagePath);
        using var img = Image.Load<Rgb24>(imagePath);
        if (keepAspect is false) { img.Mutate(p => p.Resize(targetSize, targetSize)); return ToBytes(img); }

        var ar = (float)img.Width / img.Height;
        var w = ar > 1 ? targetSize : (int)(targetSize * ar);
        var h = ar > 1 ? (int)(targetSize / ar) : targetSize;
        img.Mutate(p => p.Resize(w, h));

        using var canvas = new Image<Rgb24>(targetSize, targetSize);
        canvas.Mutate(c =>
        {
            c.BackgroundColor(Color.Black);
            c.DrawImage(img, new Point((targetSize - w) / 2, (targetSize - h) / 2), 1f);
        });
        return ToBytes(canvas);
    }

    static byte[] ToBytes(Image<Rgb24> image)
    {
        var bytes = new byte[image.Width * image.Height * 3];
        var i = 0;
        image.ProcessPixelRows(a =>
        {
            for (var y = 0; y < a.Height; y++)
            {
                var row = a.GetRowSpan(y);
                for (var x = 0; x < row.Length; x++)
                { bytes[i++] = row[x].R; bytes[i++] = row[x].G; bytes[i++] = row[x].B; }
            }
        });
        return bytes;
    }
}


