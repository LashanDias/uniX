import '../models/app_models.dart';

class MockDataService {
  static List<NoteItem> getNotes() {
    return [
      NoteItem(
        id: '1',
        title: 'Modern Communication Networks',
        subject: 'ICT',
        fileType: 'PDF',
        uploadedDate: '20 May 2025',
        description: 'This comprehensive lecture note covers the fundamental building blocks of modern communication networks. It details how data is transmitted across systems and explores the core architectural layouts used in enterprise environments.',
      ),
      NoteItem(
        id: '2',
        title: 'Data Structures & Algorithms',
        subject: 'ICT',
        fileType: 'DOCX',
        uploadedDate: '18 May 2025',
        description: 'Core concepts of arrays, linked lists, trees, graphs, sorting and searching algorithms.',
      ),
      NoteItem(
        id: '3',
        title: 'Advanced English Grammar & Syntax',
        subject: 'English',
        fileType: 'PDF',
        uploadedDate: '15 May 2025',
        description: 'Academic writing conventions, essay structures, and formal grammar rules.',
      ),
      NoteItem(
        id: '4',
        title: 'Linear Algebra & Calculus',
        subject: 'Mathematics',
        fileType: 'PDF',
        uploadedDate: '12 May 2025',
        description: 'Matrices, vector spaces, derivatives, integrals and differential equations.',
      ),
    ];
  }

  static List<ProductItem> getProducts() {
    return [
      ProductItem(
        id: '1',
        title: 'Backpack',
        category: 'Books',
        price: 2500,
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
        sellerName: 'John Doe',
        rating: 4.8,
        reviewsCount: 15,
        description: 'High capacity waterproof backpack suitable for laptop and books.',
      ),
      ProductItem(
        id: '2',
        title: 'Calculator',
        category: 'Electronics',
        price: 800,
        imageUrl: 'https://images.unsplash.com/photo-1611125832047-1d7ad1e8e48a?w=500',
        sellerName: 'Sarah Smith',
        rating: 4.9,
        reviewsCount: 32,
        description: 'Casio Scientific Calculator FX-991EX in great condition.',
      ),
      ProductItem(
        id: '3',
        title: 'Wireless Earbuds',
        category: 'Electronics',
        price: 45000,
        imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=500',
        sellerName: 'John Daily',
        rating: 4.8,
        reviewsCount: 23,
        description: 'Good quality earbuds used only for 2 months. Noise cancellation works great.',
      ),
      ProductItem(
        id: '4',
        title: 'Calculus Book',
        category: 'Books',
        price: 1200,
        imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
        sellerName: 'Amal Perera',
        rating: 4.5,
        reviewsCount: 8,
        description: 'Thomas Calculus 14th edition, clean condition without highlight marks.',
      ),
    ];
  }

  static List<JobItem> getJobs() {
    return [
      JobItem(
        id: '1',
        title: 'Data Analyst Intern',
        company: 'Dialog Axiata PLC',
        location: 'Colombo 02 • Hybrid',
        type: 'Internship',
        matchPercentage: 94,
        logoUrl: '',
      ),
      JobItem(
        id: '2',
        title: 'Junior Data Analyst',
        company: 'Creative Software',
        location: 'Colombo 03 • Full-time',
        type: 'Full-time',
        matchPercentage: 91,
        logoUrl: '',
      ),
      JobItem(
        id: '3',
        title: 'Business Intelligence Intern',
        company: 'WSO2',
        location: 'Colombo 04 • Hybrid',
        type: 'Internship',
        matchPercentage: 88,
        logoUrl: '',
      ),
    ];
  }

  static List<MicroGigItem> getMicroGigs() {
    return [
      MicroGigItem(
        id: '1',
        title: 'Sales Data Cleaning Challenge',
        company: 'ABC Analytics',
        duration: '3 days',
        requiredSkills: ['Python', 'Pandas', 'Data Cleaning'],
        stipend: 'Rs. 15,000',
      ),
      MicroGigItem(
        id: '2',
        title: 'Power BI Dashboard Optimization',
        company: 'Apex Tech Solutions',
        duration: '5 days',
        requiredSkills: ['Power BI', 'DAX', 'SQL'],
        stipend: 'Rs. 25,000',
      ),
    ];
  }

  static List<HostelItem> getHostels() {
    return [
      HostelItem(
        id: '1',
        name: 'Girls Hostel A',
        location: 'Kaduwela Road, Malabe',
        availableRooms: 80,
        pricePerMonth: 12000,
        imageUrl: '',
      ),
      HostelItem(
        id: '2',
        name: 'UniResidence Boys Lodge',
        location: 'New Town, Ratmalana',
        availableRooms: 14,
        pricePerMonth: 15000,
        imageUrl: '',
      ),
    ];
  }

  static List<LostFoundItem> getLostFoundItems() {
    return [
      LostFoundItem(
        id: '1',
        title: 'Black HP Laptop Charger',
        location: 'Library 2nd Floor Table 4',
        date: 'Today, 10:30 AM',
        type: 'Found',
        imageUrl: '',
      ),
      LostFoundItem(
        id: '2',
        title: 'Student ID Card (Amaangi T.)',
        location: 'Main Canteen Area',
        date: 'Yesterday',
        type: 'Lost',
        imageUrl: '',
      ),
    ];
  }

  static CareerPassportModel getSamplePassport() {
    return CareerPassportModel(
      name: 'Olina Tottere',
      title: 'Data Science Undergraduate',
      education: 'BSc (Hons) Data Science • University of SLTC (2021-2025)',
      skills: ['Python', 'SQL', 'Power BI', 'Data Analysis', 'Communication', 'Problem Solving'],
      verifiedSkills: ['Python', 'Pandas', 'Data Cleaning'],
      projects: ['Sales Dashboard using Power BI', 'Customer Segmentation with Python', 'Data Cleaning & Analysis using SQL'],
      certificates: ['Google Data Analytics Professional Certificate', 'Microsoft Power BI Data Analyst Associate'],
    );
  }
}
