/// Sample data and pure JOIN logic behind the interactive SQL visualizer.
class Student {
  const Student(this.id, this.name);
  final int id;
  final String name;
}

class Course {
  const Course(this.id, this.title);
  final int id;
  final String title;
}

enum JoinType { inner, left }

/// One row of a JOIN result. [student] or [course] is null when unmatched.
class JoinRow {
  const JoinRow(this.student, this.course);
  final Student? student;
  final Course? course;
  bool get matched => student != null && course != null;
}

class JoinData {
  JoinData._();

  static const List<Student> students = [
    Student(1, 'Arun'),
    Student(2, 'Priya'),
    Student(3, 'Rahul'),
  ];

  static const List<Course> courses = [
    Course(1, 'SQL'),
    Course(2, 'Python'),
    Course(4, 'Java'),
  ];
}

class JoinEngine {
  JoinEngine._();

  /// Only pairs where Students.ID == Courses.ID.
  static List<JoinRow> inner(List<Student> left, List<Course> right) {
    return [
      for (final s in left)
        for (final c in right)
          if (s.id == c.id) JoinRow(s, c),
    ];
  }

  /// Every left row; unmatched ones get a null course.
  static List<JoinRow> leftJoin(List<Student> left, List<Course> right) {
    final rows = <JoinRow>[];
    for (final s in left) {
      final matches = right.where((c) => c.id == s.id).toList();
      if (matches.isEmpty) {
        rows.add(JoinRow(s, null));
      } else {
        rows.addAll(matches.map((c) => JoinRow(s, c)));
      }
    }
    return rows;
  }

  static List<JoinRow> run(JoinType type, List<Student> left, List<Course> right) =>
      type == JoinType.inner ? inner(left, right) : leftJoin(left, right);

  static String sql(JoinType type) {
    final keyword = type == JoinType.inner ? 'INNER JOIN' : 'LEFT JOIN';
    return 'SELECT *\nFROM Students\n$keyword Courses\nON Students.ID = Courses.ID;';
  }
}
