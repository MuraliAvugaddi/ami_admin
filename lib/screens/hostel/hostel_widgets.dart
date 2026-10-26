import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// HOSTEL — shared colours + small widgets (same look as the
// mess dashboard: white cards, yellow app bar, Poppins)
// ============================================================

class HostelColors {
  static const Color chefYellow = Color(0xFFFFC800);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textPrimary = Color(0xFF171A21);
  static const Color textSecondary = Color(0xFF737B8C);
  static const Color borderColor = Color(0xFFE2E6EC);

  static const Color teal = Color(0xFF00897B);
  static const Color orange = Color(0xFFE58F00);
  static const Color greyBlue = Color(0xFF546E7A);
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFD84315);
  static const Color sosRed = Color(0xFFE53935);
  static const Color purple = Color(0xFF7656A6);
  static const Color blue = Color(0xFF3949AB);
}

class HostelLabels {
  static String category(String c) {
    switch (c) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'carpentry':
        return 'Carpentry';
      case 'cleaning':
        return 'Room cleaning';
      default:
        return 'Other';
    }
  }

  static IconData categoryIcon(String c) {
    switch (c) {
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'carpentry':
        return Icons.door_front_door_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  static Color categoryColor(String c) {
    switch (c) {
      case 'electrical':
        return HostelColors.orange;
      case 'plumbing':
        return HostelColors.blue;
      case 'carpentry':
        return const Color(0xFF8D6E63);
      case 'cleaning':
        return HostelColors.green;
      default:
        return HostelColors.purple;
    }
  }

  static String status(String s) {
    switch (s) {
      case 'open':
        return 'New';
      case 'in_progress':
        return 'In progress';
      case 'repaired':
        return 'Repaired';
      case 'closed':
        return 'Closed';
      case 'reopened':
        return 'Reopened';
      default:
        return s;
    }
  }

  static Color statusColor(String s) {
    switch (s) {
      case 'open':
        return HostelColors.orange;
      case 'in_progress':
        return HostelColors.blue;
      case 'repaired':
        return HostelColors.green;
      case 'reopened':
        return HostelColors.red;
      default:
        return HostelColors.greyBlue;
    }
  }

  static String sos(String t) {
    switch (t) {
      case 'medical':
        return 'Medical emergency';
      case 'snake':
        return 'Snake / animal';
      case 'danger':
        return 'Student in danger';
      case 'fire':
        return 'Fire / smoke';
      case 'fight':
        return 'Fight / violence';
      default:
        return 'Emergency';
    }
  }
}

// ============================================================
// HELPERS
// ============================================================

List<Map<String, dynamic>> asMapList(dynamic v) =>
    v is List ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

Map<String, dynamic> asMapOf(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

String agoText(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}');
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
}

String dateTimeText(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}');
  return d == null ? '' : DateFormat('d MMM, h:mm a').format(d.toLocal());
}

int hoursOpen(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}');
  return d == null ? 0 : DateTime.now().difference(d.toLocal()).inHours;
}

void showResult(Map<String, dynamic> res, {String okText = 'Saved'}) {
  final ok = res['success'] == true;
  Get.snackbar(
    ok ? 'Done' : 'Oops',
    '${res['message'] ?? (ok ? okText : 'Something went wrong')}',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: ok ? HostelColors.green : HostelColors.red,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
  );
}

Future<void> callNumber(String phone) async {
  if (phone.trim().isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
}

// ============================================================
// WIDGETS
// ============================================================

class HostelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? border;

  const HostelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border ?? HostelColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class HostelChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const HostelChip(this.text, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HostelEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const HostelEmpty({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: HostelColors.chefYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFB88A00)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: HostelColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// Yellow app bar like the mess dashboard
PreferredSizeWidget hostelAppBar(String title, {String? subtitle, List<Widget>? actions, bool back = true}) {
  return AppBar(
    backgroundColor: HostelColors.chefYellow,
    surfaceTintColor: HostelColors.chefYellow,
    elevation: 0,
    automaticallyImplyLeading: back,
    iconTheme: const IconThemeData(color: Colors.black),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5C4900),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
    actions: actions,
  );
}

/// Ask for a text (note / reason)
Future<String?> askText(String title, {String hint = '', String ok = 'Save', int lines = 3}) {
  final controller = TextEditingController();
  return Get.dialog<String>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: lines,
        style: GoogleFonts.poppins(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: HostelColors.chefYellow,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          onPressed: () => Get.back(result: controller.text.trim()),
          child: Text(ok),
        ),
      ],
    ),
  );
}

// ============================================================
// RESPONSIVE — same app runs on phone + website.
// Keeps content in a neat centre column on big screens.
// ============================================================

class HostelPage extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const HostelPage({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// 1 column on phone, 2 on tablet, 3 on laptop
int hostelColumns(double width, {int max = 3}) {
  if (width >= 1000) return max;
  if (width >= 640) return max >= 2 ? 2 : 1;
  return 1;
}

/// Lays cards in rows (no fixed height — each row grows to its tallest card)
class HostelResponsiveList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int maxColumns;
  final EdgeInsets padding;
  final double gap;

  const HostelResponsiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxColumns = 2,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 30),
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = hostelColumns(constraints.maxWidth, max: maxColumns);
        final rows = (itemCount / cols).ceil();
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: rows,
          itemBuilder: (context, r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      Expanded(
                        child: r * cols + c < itemCount ? itemBuilder(context, r * cols + c) : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Grey rounded search box used on all list screens
class HostelSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const HostelSearchField({super.key, required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        filled: true,
        fillColor: HostelColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Small filter pill (All / Electrical / Block A …)
class HostelFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const HostelFilterPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? HostelColors.chefYellow : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? HostelColors.chefYellow : HostelColors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.black : HostelColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : HostelColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
