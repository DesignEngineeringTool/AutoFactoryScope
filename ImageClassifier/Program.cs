using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using System.Drawing;
//using static System.Net.Mime.MediaTypeNames;

namespace ImageClassifier
{
    class Program
    {
        static void Main()
        {
            string modelPath = "C:\\Users\\Rinesh.Sewpal\\Source\\Repos\\AutoFactoryScope\\models\\onnx\\best.onnx";
            string imagePath = "C:\\Users\\Rinesh.Sewpal\\Source\\Repos\\AutoFactoryScope\\data\\test\\images\\Test1.JPG";
            int RobotCounted = 0;


            var session = new InferenceSession(modelPath);

            // Preprocess image (YOLO typical size = 640)
            int modelW = 512;
            int modelH = 512;
            var inputTensor = PreprocessImage(imagePath, modelW, modelH);

            // Create input
            var inputs = new List<NamedOnnxValue>
        {
            NamedOnnxValue.CreateFromTensor("images", inputTensor) // <-- rename if your input differs
        };

            var results = session.Run(inputs);

            // YOLO models usually output a single tensor
            var output = results.First().AsEnumerable<float>().ToArray();

            // Expected shape: [1, num_detections, (x,y,w,h,score,class)]
            int valuesPerDetection = 6;
            int numDetections = output.Length / valuesPerDetection;

            var detections = new List<Detection>();

            for (int i = 0; i < numDetections; i++)
            {
                float score = output[i * 6 + 4];
                if (score < 0.5f) continue;   // confidence threshold

                detections.Add(new Detection
                {
                    X = output[i * 6],
                    Y = output[i * 6 + 1],
                    W = output[i * 6 + 2],
                    H = output[i * 6 + 3],
                    Score = score,
                    Class = (int)output[i * 6 + 5]
                });
            }

            //Console.WriteLine($"Objects Detected: {detections.Count}");

            foreach (var det in detections)
            {
                if (det.Class == 0) {
                    Console.WriteLine($"Class {det.Class} @ {det.Score:P1}");
                    RobotCounted++;
                }
            }
            Console.WriteLine($"Robots counted: "+RobotCounted.ToString());
        }

        class Detection
        {
            public float X, Y, W, H, Score;
            public int Class;         
        }

        // -------------------------------------------------------
        // Image Preprocessing (resize -> normalize -> NCHW)
        // -------------------------------------------------------
        static DenseTensor<float> PreprocessImage(string imagePath, int targetW, int targetH)
        {
            Bitmap bmp = new Bitmap(Image.FromFile(imagePath));
            Bitmap resized = new Bitmap(bmp, new Size(targetW, targetH));

            var tensor = new DenseTensor<float>(new[] { 1, 3, targetH, targetW });

            for (int y = 0; y < targetH; y++)
            {
                for (int x = 0; x < targetW; x++)
                {
                    Color c = resized.GetPixel(x, y);

                    // Normalize to 0–1 (YOLO default)
                    tensor[0, 0, y, x] = c.R / 255f;
                    tensor[0, 1, y, x] = c.G / 255f;
                    tensor[0, 2, y, x] = c.B / 255f;
                }
            }

            return tensor;
        }
    }

}
