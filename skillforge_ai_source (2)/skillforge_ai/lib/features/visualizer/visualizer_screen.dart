import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/content_repository.dart';
import '../../services/join_engine.dart';
import '../../state/app_controller.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_screen.dart';
import 'venn_painter.dart';

enum _RowStatus { matched, kept, dropped }

class VisualizerScreen extends StatefulWidget {
  const VisualizerScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen> {
  JoinType _type = JoinType.inner;
  int? _selectedStudentId;

  List<Student> get _students => JoinData.students;
  List<Course> get _courses => JoinData.courses;

  _RowStatus _studentStatus(Student s) {
    final hasMatch = _courses.any((c) => c.id == s.id);
    if (hasMatch) return _RowStatus.matched;
    return _type == JoinType.left ? _RowStatus.kept : _RowStatus.dropped;
  }

  _RowStatus _courseStatus(Course c) =>
      _students.any((s) => s.id == c.id) ? _RowStatus.matched : _RowStatus.dropped;

  String _selectionNote() {
    final id = _selectedStudentId;
    if (id == null) {
      return 'Tap a student to see what the JOIN does with that row.';
    }
    final s = _students.firstWhere((s) => s.id == id);
    final matches = _courses.where((c) => c.id == s.id).toList();
    if (matches.isNotEmpty) {
      return '${s.name} (ID ${s.id}) matches ${matches.first.title} '
          '(ID ${matches.first.id}), so the pair appears in both JOIN types.';
    }
    return _type == JoinType.inner
        ? '${s.name} (ID ${s.id}) has no course with the same ID, so INNER JOIN '
            'drops this row.'
        : '${s.name} (ID ${s.id}) has no matching course, but LEFT JOIN keeps '
            'every left-table row and fills the course columns with NULL.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = JoinEngine.run(_type, _students, _courses);
    final innerCount = JoinEngine.inner(_students, _courses).length;
    final leftCount = JoinEngine.leftJoin(_students, _courses).length;
    final isInner = _type == JoinType.inner;
    final sql = JoinEngine.sql(_type);

    return Scaffold(
      appBar: AppBar(title: const Text('SQL JOIN Visualizer')),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                'A JOIN combines rows from two tables using a shared column. '
                'Switch the join type and watch which rows survive.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<JoinType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: JoinType.inner,
                      label: Text('INNER JOIN'),
                      icon: Icon(Icons.join_inner),
                    ),
                    ButtonSegment(
                      value: JoinType.left,
                      label: Text('LEFT JOIN'),
                      icon: Icon(Icons.join_left),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: AspectRatio(
                  aspectRatio: 2.2,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_type),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, t, _) => CustomPaint(
                      painter: VennPainter(
                        leftJoin: !isInner,
                        progress: t,
                        leftColor: scheme.primary,
                        rightColor: scheme.tertiary,
                        highlight: AppColors.success,
                        textColor: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SectionHeader('Source tables'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TableCard(
                      title: 'Students (left)',
                      headers: const ['ID', 'Name'],
                      rows: [
                        for (final s in _students)
                          _RowData(
                            cells: ['${s.id}', s.name],
                            status: _studentStatus(s),
                            selected: _selectedStudentId == s.id,
                            onTap: () => setState(() => _selectedStudentId =
                                _selectedStudentId == s.id ? null : s.id),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TableCard(
                      title: 'Courses (right)',
                      headers: const ['ID', 'Course'],
                      rows: [
                        for (final c in _courses)
                          _RowData(
                            cells: ['${c.id}', c.title],
                            status: _courseStatus(c),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  const _LegendDot(AppColors.success, 'Matched'),
                  if (!isInner) const _LegendDot(AppColors.warning, 'Kept, no match'),
                  const _LegendDot(Colors.grey, 'Dropped'),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey('$_selectedStudentId-$_type'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: scheme.onSecondaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectionNote(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSecondaryContainer, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SectionHeader(
                'Result',
                trailing: Chip(
                  label: Text('${rows.length} rows'),
                  side: BorderSide.none,
                  backgroundColor: scheme.primaryContainer,
                ),
              ),
              _ResultTable(rows: rows),
              const SectionHeader('SQL query'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        sql,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.5,
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy query',
                      icon: Icon(Icons.copy_rounded,
                          size: 20, color: scheme.onInverseSurface),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: sql));
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Query copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SectionHeader('In plain English'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInner
                          ? 'INNER JOIN keeps a row only when the ID exists in both tables. '
                              'Arun (1) and Priya (2) have courses, so they appear. Rahul (3) '
                              'has no course and the Java course (4) has no student, so both '
                              'are left out.'
                          : 'LEFT JOIN keeps every row from the left table (Students). '
                              'Arun and Priya are paired with their courses. Rahul has no '
                              'match, so he still appears, with NULL in the course columns. '
                              'The Java course is dropped because it only exists in the right table.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Compare: INNER JOIN returns $innerCount rows, LEFT JOIN returns $leftCount rows.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: scheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Test yourself with a JOIN quiz'),
                onPressed: () {
                  final difficulty =
                      widget.controller.state?.difficulty ?? 'Beginner';
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizScreen(
                        controller: widget.controller,
                        topic: ContentRepository.joinsTopic,
                        difficulty: difficulty,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowData {
  const _RowData({
    required this.cells,
    required this.status,
    this.selected = false,
    this.onTap,
  });
  final List<String> cells;
  final _RowStatus status;
  final bool selected;
  final VoidCallback? onTap;
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(headers[0],
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(headers[1],
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final r in rows) _TableRowTile(data: r),
        ],
      ),
    );
  }
}

class _TableRowTile extends StatelessWidget {
  const _TableRowTile({required this.data});
  final _RowData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (data.status) {
      case _RowStatus.matched:
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = Icons.link_rounded;
      case _RowStatus.kept:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        icon = Icons.link_off_rounded;
      case _RowStatus.dropped:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.outline;
        icon = Icons.block_rounded;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: data.selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(data.cells[0],
                      style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
                ),
                Expanded(
                  child: Text(data.cells[1],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                ),
                Icon(icon, size: 16, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.rows});
  final List<JoinRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    TextStyle head() =>
        theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    Widget cell(String? v, {required int flex}) => Expanded(
          flex: flex,
          child: v == null
              ? Text('NULL',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: scheme.outline,
                    fontWeight: FontWeight.w600,
                  ))
              : Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 2, child: Text('Students.ID', style: head())),
              Expanded(flex: 3, child: Text('Name', style: head())),
              Expanded(flex: 2, child: Text('Courses.ID', style: head())),
              Expanded(flex: 3, child: Text('Course', style: head())),
            ],
          ),
          const Divider(height: 16),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('No rows returned.'),
            ),
          for (final r in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: r.matched ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  cell('${r.student!.id}', flex: 2),
                  cell(r.student!.name, flex: 3),
                  cell(r.course == null ? null : '${r.course!.id}', flex: 2),
                  cell(r.course?.title, flex: 3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
