import 'package:flutter/material.dart';

import '../models/learning_activity.dart';
import '../models/quiz_question.dart';

class SkillInfo {
  const SkillInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.topics,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> topics;

  String? nextTopic(String current) {
    final i = topics.indexOf(current);
    if (i < 0 || i + 1 >= topics.length) return null;
    return topics[i + 1];
  }
}

class Lesson {
  const Lesson({required this.title, required this.points, required this.code});
  final String title;
  final List<String> points;
  final String code;
}

QuizQuestion _q(String topic, String difficulty, String text,
        List<String> options, int correct, String explanation) =>
    QuizQuestion(
      topic: topic,
      difficulty: difficulty,
      text: text,
      options: options,
      correctIndex: correct,
      explanation: explanation,
    );

/// All built-in learning content. Works fully offline.
class ContentRepository {
  ContentRepository._();

  static const String sqlSkill = 'SQL & Databases';
  static const String joinsTopic = 'SQL JOINs';

  static const List<SkillInfo> skills = [
    SkillInfo(
      id: 'sql',
      title: sqlSkill,
      description: 'Master queries, joins, databases and relational thinking.',
      icon: Icons.storage_rounded,
      topics: [joinsTopic, 'Filtering & Aggregation'],
    ),
    SkillInfo(
      id: 'python',
      title: 'Python Core',
      description: 'Build strong Python fundamentals and problem-solving skills.',
      icon: Icons.code_rounded,
      topics: [
        'Variables',
        'Data Types',
        'Conditionals',
        'Loops',
        'Functions',
      ],
    ),
    SkillInfo(
      id: 'ds',
      title: 'Data Structures',
      description:
          'Learn arrays, stacks, queues, trees and efficient data organization.',
      icon: Icons.account_tree_rounded,
      topics: [
        'Arrays & Lists',
        'Stacks',
        'Queues',
        'Linked Lists',
        'Trees',
      ],
    ),
  ];

  static SkillInfo skillByTitle(String title) =>
      skills.firstWhere((s) => s.title == title, orElse: () => skills.first);

  static bool hasVisualizer(String topic) => topic == joinsTopic;

  // ---------------------------------------------------------------- activities

  static LearningActivity learnActivity(String topic, String difficulty) {
    if (hasVisualizer(topic)) {
      return LearningActivity(
        title: 'Understanding SQL INNER & LEFT JOIN',
        type: ActivityType.visual,
        topic: topic,
        difficulty: difficulty,
        description:
            'Interactive Venn-diagram and table walkthrough of how JOINs combine rows.',
      );
    }
    return LearningActivity(
      title: 'Lesson: $topic',
      type: ActivityType.lesson,
      topic: topic,
      difficulty: difficulty,
      description: 'Key ideas and a code example for $topic.',
    );
  }

  static LearningActivity quizActivity(String topic, String difficulty) =>
      LearningActivity(
        title: '$topic Practice Quiz',
        type: ActivityType.quiz,
        topic: topic,
        difficulty: difficulty,
        description: 'Adaptive multiple-choice questions with instant feedback.',
      );

  // -------------------------------------------------------------------- lessons

  static Lesson? lessonFor(String topic) => _lessons[topic];

  static const Map<String, Lesson> _lessons = {
    'Filtering & Aggregation': Lesson(
      title: 'Filtering & Aggregation',
      points: [
        'WHERE filters individual rows before any grouping happens.',
        'GROUP BY collects rows into groups; COUNT, SUM, AVG, MIN and MAX summarise each group.',
        'HAVING filters whole groups after aggregation.',
      ],
      code: 'SELECT dept, COUNT(*) AS staff\nFROM employees\nWHERE active = 1\nGROUP BY dept\nHAVING COUNT(*) > 5;',
    ),
    'Variables': Lesson(
      title: 'Variables',
      points: [
        'A variable is a name bound to a value; no type declaration is needed.',
        'Names may contain letters, digits and underscores, and cannot start with a digit.',
        'Assigning a list to another name does not copy it - both names point at the same object.',
      ],
      code: 'count = 3\nname = "Priya"\na, b = 1, 2\na, b = b, a   # swap',
    ),
    'Data Types': Lesson(
      title: 'Data Types',
      points: [
        'Core types: int, float, str, bool, list, tuple, dict, set.',
        'Strings and tuples are immutable; lists, dicts and sets can change in place.',
        '// is floor division, / is true division.',
      ],
      code: 'type(3.14)    # float\n7 // 2        # 3\nt = (1, 2)    # immutable tuple',
    ),
    'Conditionals': Lesson(
      title: 'Conditionals',
      points: [
        'Use if / elif / else to choose between branches.',
        'Empty values (0, "", [], None) are falsy; most other values are truthy.',
        'A conditional expression fits on one line: x if cond else y.',
      ],
      code: 'score = 72\nif score >= 90:\n    grade = "A"\nelif score >= 60:\n    grade = "B"\nelse:\n    grade = "C"',
    ),
    'Loops': Lesson(
      title: 'Loops',
      points: [
        'for iterates over a sequence; range(n) yields 0 to n-1.',
        'break leaves the loop, continue skips to the next iteration.',
        'A loop\'s else block runs only if the loop finished without break.',
      ],
      code: 'total = 0\nfor i in range(1, 5):\n    total += i\nprint(total)  # 10',
    ),
    'Functions': Lesson(
      title: 'Functions',
      points: [
        'Define a function with def; it returns None unless you return a value.',
        'Default arguments are evaluated once, so avoid mutable defaults like [].',
        'Functions are objects and can be passed around like any value.',
      ],
      code: 'def area(w, h=1):\n    return w * h\n\nprint(area(3))      # 3\nprint(area(3, 4))   # 12',
    ),
    'Arrays & Lists': Lesson(
      title: 'Arrays & Lists',
      points: [
        'Indexing is O(1); elements are stored contiguously.',
        'Inserting at the front shifts every element, so it is O(n).',
        'Binary search needs sorted data and runs in O(log n).',
      ],
      code: 'nums = [4, 8, 15]\nnums.append(16)     # O(1) amortised\nnums.insert(0, 1)   # O(n)',
    ),
    'Stacks': Lesson(
      title: 'Stacks',
      points: [
        'A stack is LIFO: the last item pushed is the first popped.',
        'Core operations: push, pop, peek - all O(1).',
        'Used for undo history, expression evaluation and balanced-bracket checks.',
      ],
      code: 'stack = []\nstack.append(1)   # push\nstack.append(2)\nstack.pop()       # 2',
    ),
    'Queues': Lesson(
      title: 'Queues',
      points: [
        'A queue is FIFO: the first item enqueued is the first dequeued.',
        'Use collections.deque for O(1) operations at both ends.',
        'Breadth-first search relies on a queue.',
      ],
      code: 'from collections import deque\nq = deque()\nq.append(1)      # enqueue\nq.append(2)\nq.popleft()      # 1',
    ),
    'Linked Lists': Lesson(
      title: 'Linked Lists',
      points: [
        'Each node stores a value and a reference to the next node.',
        'Inserting at the head is O(1); searching is O(n).',
        'Floyd\'s tortoise-and-hare detects cycles with two pointers.',
      ],
      code: 'class Node:\n    def __init__(self, val, nxt=None):\n        self.val = val\n        self.next = nxt\n\nhead = Node(1, Node(2))',
    ),
    'Trees': Lesson(
      title: 'Trees',
      points: [
        'A tree has one root; a binary tree node has at most two children.',
        'In-order traversal of a binary search tree visits keys in ascending order.',
        'A balanced tree of n nodes has height O(log n).',
      ],
      code: 'class TreeNode:\n    def __init__(self, key):\n        self.key = key\n        self.left = None\n        self.right = None',
    ),
  };

  // ------------------------------------------------------------------ questions

  static List<QuizQuestion> questionsFor(String topic) =>
      _questions.where((q) => q.topic == topic).toList(growable: false);

  static const String _b = 'Beginner';
  static const String _i = 'Intermediate';
  static const String _a = 'Advanced';

  static final List<QuizQuestion> _questions = [
    // ---- SQL JOINs (Students ids 1,2,3  /  Courses ids 1,2,4)
    _q(joinsTopic, _b, 'Which JOIN returns only rows that have matching values in both tables?',
        ['LEFT JOIN', 'INNER JOIN', 'CROSS JOIN', 'FULL OUTER JOIN'], 1,
        'INNER JOIN keeps a row only when the ON condition matches in both tables.'),
    _q(joinsTopic, _b, 'In "Students LEFT JOIN Courses", which table is the left table?',
        ['Students', 'Courses', 'Both', 'Neither'], 0,
        'The left table is the one written before the JOIN keyword - here Students.'),
    _q(joinsTopic, _b, 'What does a LEFT JOIN put in the right-table columns when no match exists?',
        ['0', 'An empty string', 'NULL', 'The row is removed'], 2,
        'Unmatched left rows are kept, and the missing right-side values are NULL.'),
    _q(joinsTopic, _b, 'Which clause states the matching condition of a JOIN?',
        ['ORDER BY', 'ON', 'GROUP BY', 'LIMIT'], 1,
        'ON describes how rows from the two tables are paired, e.g. Students.ID = Courses.ID.'),
    _q(joinsTopic, _i, 'Students have IDs 1, 2, 3 and Courses have IDs 1, 2, 4. How many rows does the INNER JOIN on ID return?',
        ['1', '2', '3', '6'], 1,
        'Only IDs 1 and 2 exist in both tables, so 2 rows are returned.'),
    _q(joinsTopic, _i, 'With the same data, how many rows does Students LEFT JOIN Courses return?',
        ['2', '3', '4', '6'], 1,
        'Every student is kept (3 rows). Rahul (ID 3) has NULL course columns.'),
    _q(joinsTopic, _i, 'In Students LEFT JOIN Courses, which student appears with a NULL course?',
        ['Arun', 'Priya', 'Rahul', 'None of them'], 2,
        'Rahul has ID 3, and no course has ID 3.'),
    _q(joinsTopic, _a, 'For "Courses LEFT JOIN Students" (tables swapped), which course has a NULL student name?',
        ['SQL', 'Python', 'Java', 'None'], 2,
        'Now Courses is the left table. Java has ID 4, which no student has.'),
    _q(joinsTopic, _a, 'Which query returns only students that have NO matching course?',
        [
          'Students INNER JOIN Courses ON Students.ID = Courses.ID',
          'Students LEFT JOIN Courses ON Students.ID = Courses.ID WHERE Courses.ID IS NULL',
          'Students LEFT JOIN Courses ON Students.ID = Courses.ID WHERE Courses.ID = NULL',
          'Students CROSS JOIN Courses'
        ], 1,
        'Keep all students with a LEFT JOIN, then filter to the unmatched ones with IS NULL. "= NULL" is never true.'),
    _q(joinsTopic, _a, 'If one left row matches two rows in the right table, a LEFT JOIN returns...',
        ['One row', 'Two rows for that left row', 'Zero rows', 'An error'], 1,
        'JOINs produce one output row per matching pair, so the left row is repeated.'),

    // ---- SQL Filtering & Aggregation
    _q('Filtering & Aggregation', _b, 'Which function counts rows?',
        ['SUM', 'COUNT', 'AVG', 'MAX'], 1, 'COUNT returns the number of rows (or non-NULL values).'),
    _q('Filtering & Aggregation', _b, 'Which clause filters rows before they are grouped?',
        ['HAVING', 'WHERE', 'ORDER BY', 'LIMIT'], 1, 'WHERE runs before GROUP BY and filters individual rows.'),
    _q('Filtering & Aggregation', _i, 'Which clause filters groups after aggregation?',
        ['WHERE', 'HAVING', 'ON', 'DISTINCT'], 1, 'HAVING can use aggregate functions such as COUNT(*).'),
    _q('Filtering & Aggregation', _a,
        'What does "SELECT dept, COUNT(*) FROM emp GROUP BY dept HAVING COUNT(*) > 5" return?',
        [
          'Every employee',
          'Departments with more than 5 employees',
          'Employees in departments of exactly 5',
          'An error'
        ], 1,
        'Rows are grouped by department, then groups with more than 5 rows are kept.'),

    // ---- Python
    _q('Variables', _b, 'Which is a valid Python variable name?',
        ['2count', 'my-var', '_total', 'class'], 2,
        'Names cannot start with a digit, contain hyphens, or be reserved words.'),
    _q('Variables', _b, 'After x = 5 and then x = "five", what is x?',
        ['A SyntaxError occurs', 'x now refers to the string', 'A TypeError occurs', 'x stays 5'], 1,
        'Python is dynamically typed; a name can be rebound to any value.'),
    _q('Variables', _i, 'What does "a, b = 1, 2; a, b = b, a; print(a, b)" print?',
        ['1 2', '2 1', '2 2', 'Error'], 1, 'Tuple assignment swaps the values.'),
    _q('Variables', _a, 'If a = [1, 2] and b = a, then b.append(3) is run. What is a?',
        ['[1, 2]', '[1, 2, 3]', '[3]', 'Error'], 1,
        'b and a refer to the same list object, so the change is visible through both.'),
    _q('Data Types', _b, 'What is the type of 3.14?',
        ['int', 'float', 'str', 'decimal'], 1, '3.14 is a floating-point number.'),
    _q('Data Types', _b, 'Which of these is immutable?',
        ['list', 'dict', 'tuple', 'set'], 2, 'Tuples cannot be changed after creation.'),
    _q('Data Types', _i, 'What is 7 // 2 in Python?',
        ['3.5', '3', '4', '2'], 1, '// is floor division and returns 3.'),
    _q('Data Types', _a, 'What does bool("False") evaluate to?',
        ['False', 'True', 'An error', 'None'], 1, 'Any non-empty string is truthy, even "False".'),
    _q('Conditionals', _b, 'Which keyword adds another condition after an if?',
        ['else if', 'elif', 'elseif', 'otherwise'], 1, 'Python uses elif.'),
    _q('Conditionals', _b, 'What does print("A" if 5 > 3 else "B") show?',
        ['A', 'B', 'True', 'Error'], 0, '5 > 3 is true, so the first value is chosen.'),
    _q('Conditionals', _i, 'Which value is falsy?',
        ['[0]', '"False"', '0', '" "'], 2, '0 is falsy; non-empty lists and strings are truthy.'),
    _q('Conditionals', _a, 'What does 0 or "x" and "y" evaluate to?',
        ['"x"', '"y"', '0', 'True'], 1,
        '"and" binds tighter: "x" and "y" gives "y"; then 0 or "y" gives "y".'),
    _q('Loops', _b, 'How many times does "for i in range(3)" run its body?',
        ['2', '3', '4', 'Forever'], 1, 'range(3) yields 0, 1 and 2.'),
    _q('Loops', _b, 'Which statement exits a loop early?',
        ['continue', 'pass', 'break', 'exit'], 2, 'break leaves the innermost loop.'),
    _q('Loops', _i, 'What is sum(range(1, 5))?',
        ['10', '15', '9', '14'], 0, '1 + 2 + 3 + 4 = 10; the end value 5 is excluded.'),
    _q('Loops', _a, 'In a for...else loop, when does the else block run?',
        ['Always', 'Only if the loop finishes without break', 'Only after a break', 'Never'], 1,
        'The else clause runs when the loop is exhausted normally.'),
    _q('Functions', _b, 'Which keyword defines a function?',
        ['func', 'function', 'def', 'lambda'], 2, 'Functions start with def.'),
    _q('Functions', _b, 'What does a function with no return statement return?',
        ['0', 'None', 'An empty string', 'An error'], 1, 'It implicitly returns None.'),
    _q('Functions', _i, 'Given def f(a, b=2): return a * b, what is f(3)?',
        ['6', '3', 'Error', '5'], 0, 'b defaults to 2, so 3 * 2 = 6.'),
    _q('Functions', _a,
        'For def add(x, lst=[]): lst.append(x); return lst, what does the second call add(2) return after add(1)?',
        ['[2]', '[1, 2]', '[1]', 'Error'], 1,
        'The default list is created once and shared between calls.'),

    // ---- Data Structures
    _q('Arrays & Lists', _b, 'What is the index of the first element of a Python list?',
        ['1', '0', '-1', 'It depends'], 1, 'Indexing starts at 0.'),
    _q('Arrays & Lists', _b, 'What is the time complexity of reading an element by index?',
        ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'], 0, 'Index access is constant time.'),
    _q('Arrays & Lists', _i, 'Inserting at the front of a Python list is typically...',
        ['O(1)', 'O(n)', 'O(log n)', 'O(n log n)'], 1, 'Every existing element must shift by one place.'),
    _q('Arrays & Lists', _a, 'Binary search requires the array to be...',
        ['Unique', 'Sorted', 'Of even length', 'A linked list'], 1,
        'Halving the search range only works when the data is ordered.'),
    _q('Stacks', _b, 'What ordering does a stack follow?',
        ['FIFO', 'LIFO', 'Random', 'Priority'], 1, 'Last in, first out.'),
    _q('Stacks', _b, 'Which operation adds an item to a stack?',
        ['pop', 'push', 'peek', 'enqueue'], 1, 'push places an item on top.'),
    _q('Stacks', _i, 'After pushing 1, 2, 3 and then popping once, which value is returned?',
        ['1', '2', '3', 'None'], 2, 'The last pushed value, 3, comes off first.'),
    _q('Stacks', _a, 'Which problem is most naturally solved with a stack?',
        ['Breadth-first search', 'Checking balanced parentheses', 'Round-robin scheduling', 'Level-order traversal'], 1,
        'Opening brackets are pushed and matched against closing ones in reverse order.'),
    _q('Queues', _b, 'What ordering does a queue follow?',
        ['LIFO', 'FIFO', 'Sorted', 'Random'], 1, 'First in, first out.'),
    _q('Queues', _b, 'Adding an item to a queue is called...',
        ['push', 'enqueue', 'pop', 'peek'], 1, 'enqueue adds at the rear.'),
    _q('Queues', _i, 'After enqueuing 1, 2, 3 and dequeuing once, which value is returned?',
        ['3', '2', '1', 'None'], 2, 'The first item enqueued, 1, leaves first.'),
    _q('Queues', _a, 'Breadth-first search uses which data structure?',
        ['Stack', 'Queue', 'Heap', 'Hash table'], 1, 'A queue visits nodes level by level.'),
    _q('Linked Lists', _b, 'Each node of a singly linked list contains...',
        ['Only data', 'Data and a reference to the next node', 'An index only', 'A key only'], 1,
        'The next reference chains the nodes together.'),
    _q('Linked Lists', _b, 'The "next" pointer of the last node is...',
        ['The head', 'Itself', 'None / null', 'The tail'], 2, 'It marks the end of the list.'),
    _q('Linked Lists', _i, 'Inserting at the head of a singly linked list is...',
        ['O(n)', 'O(1)', 'O(log n)', 'O(n^2)'], 1, 'Only a couple of pointers change.'),
    _q('Linked Lists', _a, 'Which technique detects a cycle in a linked list efficiently?',
        ["Floyd's tortoise and hare", 'Binary search', 'Bubble sort', 'Hashing the values only'], 0,
        'A slow and a fast pointer meet if and only if there is a cycle.'),
    _q('Trees', _b, 'The topmost node of a tree is called the...',
        ['Leaf', 'Root', 'Branch', 'Parent only'], 1, 'The root has no parent.'),
    _q('Trees', _b, 'How many children can a node of a binary tree have at most?',
        ['1', '2', '3', 'Unlimited'], 1, 'Binary means at most two children.'),
    _q('Trees', _i, 'In-order traversal of a binary search tree visits keys in...',
        ['Random order', 'Ascending order', 'Level order', 'Reverse insertion order'], 1,
        'Left, node, right gives sorted order for a BST.'),
    _q('Trees', _a, 'What is the height of a balanced binary search tree with n nodes?',
        ['O(n)', 'O(log n)', 'O(1)', 'O(n^2)'], 1, 'Each level roughly doubles the node count.'),
  ];
}
