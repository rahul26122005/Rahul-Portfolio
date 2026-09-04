// no top-level dart: imports required here

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/app_drawer.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';
import 'package:my_flutter_webside/utils/file_downloader.dart';

import 'resume_data.dart';
import 'resume_pdf_generator.dart';
import 'resume_docx_generator.dart';

class ResumeViewPage extends StatefulWidget {
  const ResumeViewPage({super.key});

  @override
  State<ResumeViewPage> createState() => _ResumeViewPageState();
}

class _ResumeViewPageState extends State<ResumeViewPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    final Color cardColor = theme.cardColor;

    final Color accentColor = theme.colorScheme.secondary;

    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDarkMode ? Colors.white : Colors.black);

    final Color secondaryTextColor =
        theme.textTheme.bodyMedium?.color?.withAlpha(204) ??
        (isDarkMode ? Colors.white70 : Colors.black87);

    const double bodyFontSize = 13.0;

    const double sectionHeaderSize = 16.0;

    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 700;

    final resume = sampleResume();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      endDrawer: DrawerPage(isDarkMode: isDarkMode, onThemeChange: (_) {}),

      // =================================================
      // APP BAR
      // =================================================
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, AppRoutes.dashboard);
          },

          icon: Icon(Icons.arrow_back, color: textColor),
        ),

        title: Text(
          "My Resume",

          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),

        actions: [
          // DOWNLOAD
          IconButton(
            icon: Icon(Icons.download, color: textColor),

            tooltip: 'Download resume',

            onPressed: _isSaving ? null : _showDownloadDialog,
          ),
        ],

        backgroundColor: theme.appBarTheme.backgroundColor ?? cardColor,

        elevation: 1,

        centerTitle: true,

        iconTheme: IconThemeData(color: textColor),
      ),

      // =================================================
      // BODY
      // =================================================
      body: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 850),

                margin: EdgeInsets.symmetric(
                  vertical: isMobile ? 0 : 40,

                  horizontal: isMobile ? 0 : 20,
                ),

                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 60,

                  vertical: isMobile ? 40 : 60,
                ),

                decoration: BoxDecoration(
                  color: cardColor,

                  boxShadow: isMobile
                      ? null
                      : [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withAlpha(10)
                                : Colors.black.withAlpha(26),

                            blurRadius: 20,

                            offset: const Offset(0, 10),
                          ),
                        ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ================= HEADER =================
                    Text(
                      resume.name,

                      style: TextStyle(
                        fontSize: 42,

                        fontWeight: FontWeight.bold,

                        letterSpacing: 1.5,

                        color: textColor,

                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      resume.headline,

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.w500,

                        letterSpacing: 1.2,

                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      resume.subHeadline,

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.w500,

                        letterSpacing: 1.2,

                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildContactLine(resume, secondaryTextColor),

                    const SizedBox(height: 10),

                    Divider(thickness: 1.5, color: accentColor),

                    const SizedBox(height: 25),

                    // ================= SUMMARY =================
                    _buildSectionHeader(
                      "SUMMARY",

                      accentColor,

                      sectionHeaderSize,

                      textColor,
                    ),

                    Text(
                      resume.summary,

                      style: TextStyle(
                        fontSize: bodyFontSize,

                        height: 1.6,

                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ================= SKILLS =================
                    _buildSectionHeader(
                      "TECHNICAL SKILLS",

                      accentColor,

                      sectionHeaderSize,

                      textColor,
                    ),

                    _buildSkillGrid(resume.skills, secondaryTextColor),

                    const SizedBox(height: 10),

                    // ================= EXPERIENCE =================
                    _buildSectionHeader(
                      "EXPERIENCE",

                      accentColor,

                      sectionHeaderSize,

                      textColor,
                    ),

                    ...resume.projects.map(
                      (project) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),

                        child: _buildExperienceItem(
                          title: project.title,

                          date: project.date,

                          subTitle: project.subTitle,

                          bullets: project.bullets,

                          titleColor: textColor,

                          bodyColor: secondaryTextColor,
                        ),
                      ),
                    ),

                    // ================= EDUCATION =================
                    _buildSectionHeader(
                      "EDUCATION",

                      accentColor,

                      sectionHeaderSize,

                      textColor,
                    ),

                    ...resume.education.map(
                      (education) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),

                        child: _buildExperienceItem(
                          title: education.title,

                          date: education.date,

                          subTitle: education.subTitle,

                          bullets: education.bullets,

                          titleColor: textColor,

                          bodyColor: secondaryTextColor,
                        ),
                      ),
                    ),

                    // ================= ADDITIONAL =================
                    _buildSectionHeader(
                      "ADDITIONAL INFORMATION",

                      accentColor,

                      sectionHeaderSize,

                      textColor,
                    ),

                    ...resume.additional.map(
                      (item) => _buildAdditionalPoint(
                        item,

                        textColor,

                        secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildSectionHeader(
                      'EXTERNAL LINKS',
                      accentColor,
                      sectionHeaderSize,
                      textColor,
                    ),
                    ...resume.external.map(
                      (externalItem) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildExternalLink(
                          externalItem,
                          resume,
                          secondaryTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDownloadDialog() async {
    final selected = await showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Download resume'),

          content: const Text('Which document format do you want?'),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'docx'),

              child: const Text('DOCX'),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, 'pdf'),

              child: const Text('PDF'),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, null),

              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await _downloadResume(selected);
    }
  }

  Future<void> _downloadResume(String type) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final resume = sampleResume();

      final bytes = type == 'pdf'
          ? await generateResumePdf(resume)
          : generateResumeDocx(resume);

      final fileName =
          'Rahul_Rajarajan_Resume.${type == 'pdf' ? 'pdf' : 'docx'}';

      final savedPath = await saveFileBytes(bytes, fileName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Starting download of $fileName'
                : 'Resume saved to: $savedPath',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildSectionHeader(
    String title,
    Color color,
    double fontSize,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: TextStyle(
            fontWeight: FontWeight.bold,

            fontSize: fontSize,

            letterSpacing: 1.1,

            color: textColor,
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 15),

          height: 1.5,

          color: color,
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactLine(Resume resume, Color textColor) {
    final segments = resume.contactLine.split(' | ');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          Text(
            segments[i],
            style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
          ),
          if (i < segments.length - 1)
            Text(
              ' | ',
              style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
            ),
        ],
      ],
    );
  }

  Widget _buildExternalLink(
    String externalItem,
    Resume resume,
    Color textColor,
  ) {
    if (externalItem.startsWith('LinkedIn:')) {
      return TextButton(
        onPressed: () => _launchUrl(resume.linkedInUrl),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          externalItem,
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return Text(
      externalItem,
      style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
    );
  }

  Widget _buildSkillGrid(List<String> skills, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: skills
          .map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 8),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),

                    child: Icon(
                      Icons.circle,

                      size: 6,

                      color: textColor.withAlpha(150),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      skill,

                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExperienceItem({
    required String title,
    required String date,
    String? subTitle,
    required List<String> bullets,
    required Color titleColor,
    required Color bodyColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Expanded(
              child: Text(
                title,

                style: TextStyle(
                  fontWeight: FontWeight.bold,

                  fontSize: 14,

                  color: titleColor,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Text(
              date,

              style: TextStyle(
                fontWeight: FontWeight.bold,

                fontSize: 13,

                color: titleColor,
              ),
            ),
          ],
        ),

        if (subTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),

            child: Text(
              subTitle,

              style: TextStyle(fontSize: 13, color: bodyColor),
            ),
          ),

        const SizedBox(height: 4),

        ...bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),

                  child: Icon(Icons.circle, size: 5, color: bodyColor),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    bullet,

                    style: TextStyle(
                      fontSize: 13,

                      height: 1.5,

                      color: bodyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichBulletPoint(
    String label,
    String value,
    Color textColor,
    Color bulletColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),

            child: Icon(Icons.circle, size: 5, color: bulletColor),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: textColor, height: 1.5),

                children: [
                  TextSpan(
                    text: label,

                    style: TextStyle(
                      fontWeight: FontWeight.bold,

                      color: textColor,
                    ),
                  ),

                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalPoint(
    String text,
    Color textColor,
    Color bulletColor,
  ) {
    final separatorIndex = text.indexOf(':');

    if (separatorIndex >= 0) {
      return _buildRichBulletPoint(
        text.substring(0, separatorIndex + 1),

        text.substring(separatorIndex + 1).trim(),

        textColor,

        bulletColor,
      );
    }

    return _buildRichBulletPoint('', text, textColor, bulletColor);
  }
}
