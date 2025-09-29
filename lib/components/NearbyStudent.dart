import 'package:flutter/material.dart';

class StudentTile extends StatefulWidget {
  final String studentName;
  final List<String> docList; // fixed camelCase
  final Function(bool?)? selectDoc;

  const StudentTile({
    super.key,
    required this.studentName,
    required this.docList,
    required this.selectDoc,
  });

  @override
  State<StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<StudentTile> {
  bool _isExpanded = false; // track expansion state

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Top Row: Profile + Name + Expand Icon
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile image + Name
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/images/user.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color:
                          Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  )
                ],
              ),
            ),

            // Expanded content: list of doc names
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.docList.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "📄 $doc",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color:
                        Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
