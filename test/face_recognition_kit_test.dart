import 'package:face_recognition_kit/face_recognition_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Attendance matching logic', () {
    final service = AttendanceService();
    final profile = FaceProfile(
      id: '1',
      name: 'Nitin',
      embedding: [0.1, 0.2, 0.3],
    );

    service.registerFace(profile.id, profile.name, profile.embedding);

    final distance = service.compareEmbeddings(
      [0.1, 0.2, 0.3],
      [0.1, 0.2, 0.31],
    );

    expect(distance < 0.6, isTrue); // Should match within threshold
  });
}
