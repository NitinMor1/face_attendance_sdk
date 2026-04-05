import 'dart:js_interop';

@JS('FaceDetector')
extension type FaceDetector._(JSObject _) implements JSObject {
  external static JSPromise<FaceDetector> createFromOptions(
    FilesetResolver resolver,
    FaceDetectorOptions options,
  );

  external FaceDetectorResult detect(JSObject image);
  external FaceDetectorResult detectForVideo(JSObject video, double timestamp);
  external void close();
}

@JS('FilesetResolver')
extension type FilesetResolver._(JSObject _) implements JSObject {
  external static JSPromise<FilesetResolver> forVisionTasks(JSString path);
}

@JS()
extension type FaceDetectorOptions._(JSObject _) implements JSObject {
  external factory FaceDetectorOptions({
    BaseOptions baseOptions,
    JSString runningMode,
    double minDetectionConfidence,
  });
}

@JS()
extension type BaseOptions._(JSObject _) implements JSObject {
  external factory BaseOptions({
    JSString modelAssetPath,
    JSString delegate,
  });
}

@JS()
extension type FaceDetectorResult._(JSObject _) implements JSObject {
  external JSArray<Detection> detections;
}

@JS()
extension type Detection._(JSObject _) implements JSObject {
  external BoundingBox? boundingBox;
  external JSArray<Category> categories;
}

@JS()
extension type BoundingBox._(JSObject _) implements JSObject {
  external double originX;
  external double originY;
  external double width;
  external double height;
}

@JS()
extension type Category._(JSObject _) implements JSObject {
  external double score;
  external JSString? categoryName;
}
