class Article {
  final String files;
  final String type_files;
  const Article({this.files, this.type_files});

  factory Article.fromJSON(Map<String, dynamic> json) {
    return Article(
      files: json['files'],
      type_files: json['type_files'],
    );
  }
}
