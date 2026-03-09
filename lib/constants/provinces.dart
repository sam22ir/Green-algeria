class Province {
  final int id;
  final String nameEn;
  final String nameAr;

  const Province({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });
}

// For demonstration, a few main provinces are included. 
// A real app would have all 58 here or fetched from the backend.
const List<Province> algeriaProvinces = [
  Province(id: 1, nameEn: 'Adrar', nameAr: 'أدرار'),
  Province(id: 2, nameEn: 'Chlef', nameAr: 'الشلف'),
  Province(id: 3, nameEn: 'Laghouat', nameAr: 'الأغواط'),
  Province(id: 4, nameEn: 'Oum El Bouaghi', nameAr: 'أم البواقي'),
  Province(id: 5, nameEn: 'Batna', nameAr: 'باتنة'),
  Province(id: 6, nameEn: 'Béjaïa', nameAr: 'بجاية'),
  Province(id: 7, nameEn: 'Biskra', nameAr: 'بسكرة'),
  Province(id: 8, nameEn: 'Béchar', nameAr: 'بشار'),
  Province(id: 9, nameEn: 'Blida', nameAr: 'البليدة'),
  Province(id: 10, nameEn: 'Bouira', nameAr: 'البويرة'),
  Province(id: 11, nameEn: 'Tamanrasset', nameAr: 'تمنراست'),
  Province(id: 12, nameEn: 'Tébessa', nameAr: 'تبسة'),
  Province(id: 13, nameEn: 'Tlemcen', nameAr: 'تلمسان'),
  Province(id: 14, nameEn: 'Tiaret', nameAr: 'تيارت'),
  Province(id: 15, nameEn: 'Tizi Ouzou', nameAr: 'تيزي وزو'),
  Province(id: 16, nameEn: 'Algiers', nameAr: 'الجزائر'),
  Province(id: 17, nameEn: 'Djelfa', nameAr: 'الجلفة'),
  Province(id: 18, nameEn: 'Jijel', nameAr: 'جيجل'),
  Province(id: 19, nameEn: 'Sétif', nameAr: 'سطيف'),
  Province(id: 20, nameEn: 'Saïda', nameAr: 'سعيدة'),
  Province(id: 21, nameEn: 'Skikda', nameAr: 'سكيكدة'),
  Province(id: 22, nameEn: 'Sidi Bel Abbès', nameAr: 'سيدي بلعباس'),
  Province(id: 23, nameEn: 'Annaba', nameAr: 'عنابة'),
  Province(id: 24, nameEn: 'Guelma', nameAr: 'قالمة'),
  Province(id: 25, nameEn: 'Constantine', nameAr: 'قسنطينة'),
  Province(id: 26, nameEn: 'Médéa', nameAr: 'المدية'),
  Province(id: 27, nameEn: 'Mostaganem', nameAr: 'مستغانم'),
  Province(id: 28, nameEn: 'M\'Sila', nameAr: 'المسيلة'),
  Province(id: 29, nameEn: 'Mascara', nameAr: 'معسكر'),
  Province(id: 30, nameEn: 'Ouargla', nameAr: 'ورقلة'),
  Province(id: 31, nameEn: 'Oran', nameAr: 'وهران'),
  // ... rest up to 58 in real app
];
