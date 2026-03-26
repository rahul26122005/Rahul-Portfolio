/*
class ResumeModel {
  final String id;
  final String title;
  final String name;
  final String summary;
  final String photoUrl;
  final bool isPublished;

  ResumeModel({
    required this.id,
    required this.title,
    required this.name,
    required this.summary,
    required this.photoUrl,
    required this.isPublished,
  });

  factory ResumeModel.fromDoc(doc) {
    final data = doc.data();
    return ResumeModel(
      id: doc.id,
      title: data['title'] ?? '',
      name: data['name'] ?? '',
      summary: data['summary'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      isPublished: data['isPublished'] ?? false,
    );
  }
}
*/