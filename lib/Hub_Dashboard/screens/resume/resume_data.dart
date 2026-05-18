class ResumeBullet {
  final String text;
  ResumeBullet(this.text);
}

class ResumeExperience {
  final String title;
  final String date;
  final String? subTitle;
  final List<String> bullets;

  ResumeExperience({
    required this.title,
    required this.date,
    this.subTitle,
    required this.bullets,
  });
}

class Resume {
  final String name;
  final String headline;
  final String subHeadline;
  final String contactLine;
  final String summary;
  final List<String> skills;
  final List<ResumeExperience> projects;
  final List<ResumeExperience> education;
  final List<String> additional;

  Resume({
    required this.name,
    required this.headline,
    required this.subHeadline,
    required this.contactLine,
    required this.summary,
    required this.skills,
    required this.projects,
    required this.education,
    required this.additional,
  });
}

Resume sampleResume() {
  return Resume(
    name: 'RAHUL RAJARAJAN',
    headline: 'PRE-FINAL YEAR STUDENT',
    subHeadline: 'BIOMEDICAL ENGINEER',
    contactLine:
        'Phone: +91-7448665022 | Email: rahulr26122005@gmail.com | LinkedIn: www.linkedin.com/in/rahulrajabme05 | Location: Kallakurichi, Tamil Nadu, India',
    summary:
        "   I'm a pre-final year student in Biomedical Engineering, and I try to stay motivated about details in my work. I have this strong pull toward technology and healthcare, plus software stuff like development. It seems like Flutter and Firebase are areas where I have some real skills, along with basic Python. I built an Attendance Management System which had role-based access and automated reports. Biomedical instrumentation is something I know a bit about from classes. Communication and problem-solving in teams are strengths. I want to use these technical skills in innovative places.",
    skills: [
      'Diploma in Computer Applications (DCA)',
      'Programming Language: Flutter, Basic Python',
      'Biomedical instrumentation',
    ],
    projects: [
      ResumeExperience(
        title: 'Attendance Management System',
        date: 'Dec 2025 - Jan 2026',
        subTitle: 'Personal Project using Flutter and Firebase',
        bullets: [
          'Monthly report generation with automated table calculation for total No. days Presents and Absent.',
          'Separate login for Teachers and students with different access levels and functionalities.',
          'Implemented a user-friendly interface for seamless attendance tracking and management.',
        ],
      ),
      ResumeExperience(
        title: 'Hospital Training at Aswini Hospital, Villupuram',
        date: '07/07/2025 - 19/07/2025',
        subTitle: 'Internship focused on Biomedical Equipments',
        bullets: [
          'Visited and learned about various biomedical equipments such as ECG machines, X-ray machines, and patient monitoring systems, and their applications in patient care.',
        ],
      ),
      ResumeExperience(
        title: 'Hospital Training at Aswini Hospital, Villupuram',
        date: '07/07/2025 - 19/07/2025',
        subTitle: 'Internship focused on Biomedical Equipments',
        bullets: [
          'Visited and learned about various biomedical equipments such as ECG machines, X-ray machines, and patient monitoring systems, and their applications in patient care.',
        ],
      ),
    ],
    education: [
      ResumeExperience(
        title: 'Bachelor of Engineering in Biomedical Engineering',
        date: '2023 - 2027',
        subTitle: 'Mahendra College of Engineering, Salem, Tamil Nadu',
        bullets: ['CGPA: 7.6/10 upto 5th semester.'],
      ),
      ResumeExperience(
        title: 'Higher Secondary Education',
        date: '2022 - 2023',
        subTitle: 'Goverment Boys Hr. Sec. School, kallakurichi, Tamil Nadu',
        bullets: ['Percentage: 58%'],
      ),
    ],
    additional: [
      'Languages: Tamil (Native), English (Professional), Hindi (Partial Learning).',
      'Certifications: Diploma in Computer Applications (DCA).',
    ],
  );
}
