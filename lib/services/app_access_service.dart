class AppAccessService {
  static const Set<String> adminEmails = {
    'amashanki191@gmail.com',
    'cit-24-01-0361@sltc.ac.lk',
    'malshikulasekara4816@gmail.com',
    'sandupamabimandhi@gmail.com',
    'jaksikasivakumar@gmail.com',
  };

  static bool isInstitutionalEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    return normalized != null && RegExp(r'^[^@]+@sltc\.ac\.lk$').hasMatch(normalized);
  }

  static bool isAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    return normalized != null && adminEmails.contains(normalized);
  }

  static bool canManageOwnedResource(String currentUserId, String ownerId, {bool isAdmin = false}) {
    return isAdmin || currentUserId == ownerId;
  }
}
