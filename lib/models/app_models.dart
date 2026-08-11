class NoteItem {
  final String id;
  final String title;
  final String subject;
  final String fileType;
  final String uploadedDate;
  final String description;

  NoteItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.fileType,
    required this.uploadedDate,
    required this.description,
  });
}

class ProductItem {
  final String id;
  final String title;
  final String category;
  final double price;
  final String imageUrl;
  final String sellerName;
  final double rating;
  final int reviewsCount;
  final String description;

  ProductItem({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    required this.rating,
    required this.reviewsCount,
    required this.description,
  });
}

class JobItem {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type; // Hybrid, Full-time, Internship
  final int matchPercentage;
  final String logoUrl;

  JobItem({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.matchPercentage,
    required this.logoUrl,
  });
}

class MicroGigItem {
  final String id;
  final String title;
  final String company;
  final String duration;
  final List<String> requiredSkills;
  final String stipend;

  MicroGigItem({
    required this.id,
    required this.title,
    required this.company,
    required this.duration,
    required this.requiredSkills,
    required this.stipend,
  });
}

class HostelItem {
  final String id;
  final String name;
  final String location;
  final int availableRooms;
  final double pricePerMonth;
  final String imageUrl;

  HostelItem({
    required this.id,
    required this.name,
    required this.location,
    required this.availableRooms,
    required this.pricePerMonth,
    required this.imageUrl,
  });
}

class LostFoundItem {
  final String id;
  final String title;
  final String location;
  final String date;
  final String type; // Lost or Found
  final String imageUrl;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.type,
    required this.imageUrl,
  });
}

class CareerPassportModel {
  final String name;
  final String title;
  final String education;
  final List<String> skills;
  final List<String> verifiedSkills;
  final List<String> projects;
  final List<String> certificates;

  CareerPassportModel({
    required this.name,
    required this.title,
    required this.education,
    required this.skills,
    required this.verifiedSkills,
    required this.projects,
    required this.certificates,
  });
}
