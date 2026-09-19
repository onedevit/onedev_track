import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../main.dart'; // للوصول لـ themeNotifier

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<ClientUser> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // قاموس شامل ودقيق لجميع دول جامعة الدول العربية الـ 22 كاملة مكملة بولاياتها ومدنها
  static const Map<String, Map<String, List<String>>> _locationData = {
    // -----------------------------------------------------------------
    // 1. دول المغرب العربي وشمال إفريقيا (Maghreb & North Africa)
    // -----------------------------------------------------------------
    'تونس': {
      'تونس العاصمة': ['تونس', 'المرسى', 'سيدي بوسعيد', 'باردو', 'قرطاج', 'حلق الوادي', 'الكرم'],
      'أريانة': ['أريانة', 'رواد', 'سكرة', 'المنيهلة', 'قلعة الأندلس'],
      'بن عروس': ['بن عروس', 'حمّام الأنف', 'رادس', 'مقرين', 'المروج', 'الزهراء', 'فوشانة'],
      'منوبة': ['منوبة', 'دوار هيشر', 'وادي الليل', 'طبربة', 'الجديدة'],
      'نابل': ['نابل', 'الحمامات', 'قليبية', 'منزل تميم', 'قرمبالية', 'الهوارية'],
      'زغوان': ['زغوان', 'الفحص', 'الناظور'],
      'بنزرت': ['بنزرت', 'منزل بورقيبة', 'راس الجبل', 'ماطر', 'جومين'],
      'باجة': ['باجة', 'مجاز الباب', 'تستور', 'نفزة'],
      'جندوبة': ['جندوبة', 'طبرقة', 'عين دراهم', 'غار الدماء'],
      'الكاف': ['الكاف', 'تاجروين', 'دهماني'],
      'سليانة': ['سليانة', 'مكثر', 'بوعرادة'],
      'سوسة': ['سوسة', 'حمام سوسة', 'القنطاوي', 'مصرين', 'النفيضة', 'القلعة الكبرى', 'القلعة الصغرى'],
      'المنستير': ['المنستير', 'مكنين', 'جمال', 'الفرينة', 'قصر هلال', 'طبلبة'],
      'المهدية': ['المهدية', 'قصور الساف', 'الشابة'],
      'صفاقس': ['صفاقس', 'ساقية الزيت', 'ساقية الداير', 'طينة', 'المحرس', 'قرقنة'],
      'القيروان': ['القيروان', 'بوحجلة', 'السبيخة', 'حفوز', 'وسلاتية'],
      'القصرين': ['القصرين', 'سبيطلة', 'فريانة', 'تالة'],
      'سيدي بوزيد': ['سيدي بوزيد', 'الرقاب', 'المكناسي'],
      'قابس': ['قابس', 'الحامة', 'مارث', 'مطماطة'],
      'مدنين': ['مدنين', 'جربة حومة السوق', 'جربة ميدون', 'جرجيس', 'بنقردان'],
      'تطاوين': ['تطاوين', 'غمراسن', 'رمادة'],
      'قفصة': ['قفصة', 'المتلاوي', 'أم العرائس', 'الرديف'],
      'توزر': ['توزر', 'دقاش', 'نفطة'],
      'قبلي': ['قبلي', 'دوز', 'سوق الأحد'],
    },
    'الجزائر': {
      'الجزائر العاصمة': ['الجزائر', 'باب الوادي', 'الشراقة', 'الدار البيضاء', 'زرالدة'],
      'وهران': ['وهران', 'السانية', 'أرزيو', 'عين الترك'],
      'قسنطينة': ['قسنطينة', 'الخروب', 'زيغود يوسف'],
      'عنابة': ['عنابة', 'البوني', 'الحجار'],
      'سطيف': ['سطيف', 'العلمة', 'عين ولمان'],
      'البليدة': ['البليدة', 'بوفاريك', 'العفرون'],
      'تلمسان': ['تلمسان', 'مغنية', 'الرمشي'],
      'باتنة': ['باتنة', 'عين التوتة'],
      'بجاية': ['بجاية', 'أقبو'],
      'بسكرة': ['بسكرة', 'طولقة'],
      'تيزي وزو': ['تيزي وزو', 'عزازقة'],
      'الشلف': ['الشلف', 'تنس'],
      'مستغانم': ['مستغانم', 'عين تادلس'],
      'ورقلة': ['ورقلة', 'حاسي مسعود'],
      'غرداية': ['غرداية', 'متليلي'],
      'سكيكدة': ['سكيكدة', 'الحروش'],
      'جيجل': ['جيجل', 'الطاهير'],
    },
    'المغرب': {
      'الرباط - سلا - القنيطرة': ['الرباط', 'سلا', 'القنيطرة', 'الصخيرات'],
      'الدار البيضاء - سطات': ['الدار البيضاء', 'المحمدية', 'سطات', 'الجديدة'],
      'مراكش - أسفي': ['مراكش', 'أسفي', 'الصويرة'],
      'فاس - مكناس': ['فاس', 'مكناس', 'تازة'],
      'طنجة - تطوان - الحسيمة': ['طنجة', 'تطوان', 'الحسيمة', 'العرائش'],
      'الشرق': ['وجدة', 'الناظور', 'بركان'],
      'سوس - ماسة': ['أكادير', 'تارودانت', 'تزنيت'],
      'العيون - الساقية الحمراء': ['العيون', 'بوجدور'],
      'الداخلة - وادي الذهب': ['الداخلة'],
    },
    'ليبيا': {
      'طرابلس': ['طرابلس', 'تاجوراء', 'أبو سليم'],
      'بنغازي': ['بنغازي', 'الصابري', 'البركة'],
      'مصراتة': ['مصراتة', 'زليتن'],
      'الزاوية': ['الزاوية', 'صرامان'],
      'البيضاء': ['البيضاء', 'شحات'],
      'سبها': ['سبها', 'مرزق'],
      'طبرق': ['طبرق', 'امساعد'],
      'سرت': ['سرت'],
    },
    'موريتانيا': {
      'نواكشوط': ['نواكشوط الشمالية', 'نواكشوط الغربية', 'نواكشوط الجنوبية'],
      'داخلت نواذيبو': ['نواذيبو'],
      'اترارزة': ['روصو'],
      'الحوض الشرقي': ['نعمة'],
    },
    'مصر': {
      'محافظة القاهرة': ['القاهرة', 'مدينة نصر', 'التجمع الخامس', 'المعادي', 'مصر الجديدة', 'الشروق'],
      'محافظة الجيزة': ['الجيزة', '6 أكتوبر', 'الشيخ زايد', 'الهرم', 'الدقي'],
      'محافظة الإسكندرية': ['الإسكندرية', 'سموحة', 'المنتزه', 'العجمي', 'برج العرب'],
      'محافظة الدقهلية': ['المنصورة', 'ميت غمر'],
      'محافظة الشرقية': ['الزقازيق', 'العاشر من رمضان'],
      'محافظة القليوبية': ['بنها', 'شبرا الخيمة', 'العبور'],
      'محافظة البحر الأحمر': ['الغردقة', 'الجونة', 'مرسى علم'],
      'محافظة جنوب سيناء': ['شرم الشيخ', 'دهب', 'نويبع'],
      'محافظة مطروح': ['مرسى مطروح', 'العلمين'],
    },
    'السودان': {
      'ولاية الخرطوم': ['الخرطوم', 'أم درمان', 'بحري'],
      'ولاية البحر الأحمر': ['بورتسودان', 'سواكن'],
      'ولاية كسلا': ['كسلا'],
      'ولاية القضارف': ['القضارف'],
      'ولاية الجزيرة': ['ود مدني'],
      'الولاية الشمالية': ['دنقلا', 'مروي'],
    },
    'الصومال': {
      'إقليم بنادر': ['مقديشو'],
      'إقليم وقويي جالبيد': ['هرجيسا'],
      'إقليم باري': ['بوساسو'],
      'إقليم بايكول': ['بيدوا'],
      'إقليم جوبا السفلى': ['كيسمايو'],
    },
    'جيبوتي': {
      'إقليم جيبوتي': ['جيبوتي العاصمة'],
      'إقليم علي صبيح': ['علي صبيح'],
      'إقليم تاجورة': ['تاجورة'],
      'إقليم دخيل': ['دخيل'],
      'إقليم أوبوك': ['أوبوك'],
    },
    'جزر القمر': {
      'جزيرة أنجوان': ['موتسامودو'],
      'جزيرة القمر الكبرى': ['موروني'],
      'جزيرة موهيلي': ['فومبوني'],
    },

    // -----------------------------------------------------------------
    // 2. دول الخليج العربي (GCC)
    // -----------------------------------------------------------------
    'السعودية': {
      'منطقة الرياض': ['الرياض', 'الخرج', 'الدرعية', 'المجمعة', 'الدوادمي'],
      'منطقة مكة المكرمة': ['جدة', 'مكة المكرمة', 'الطائف', 'القنفذة', 'رابغ'],
      'المنطقة الشرقية': ['الدمام', 'الخبر', 'الظهران', 'الأحساء', 'القطيف', 'الجبيل'],
      'منطقة المدينة المنورة': ['المدينة المنورة', 'ينبع', 'العلا'],
      'منطقة القصيم': ['بريدة', 'عنيزة', 'الرس'],
      'منطقة عسير': ['أبها', 'خميس مشيط', 'محايل عسير'],
      'منطقة تبوك': ['تبوك', 'نيوم', 'الوجه'],
      'منطقة حائل': ['حائل'],
      'منطقة جازان': ['جازان', 'صبيا'],
      'منطقة نجران': ['نجران'],
      'منطقة الحدود الشمالية': ['عرعر'],
      'منطقة الجوف': ['سكاكا'],
      'منطقة الباحة': ['الباحة'],
    },
    'الإمارات': {
      'إمارة دبي': ['دبي', 'ديرة', 'بر دبي', 'جبل علي', 'دبي ماربيا'],
      'إمارة أبوظبي': ['أبوظبي', 'العين', 'الظفرة'],
      'إمارة الشارقة': ['الشارقة', 'خورفكان', 'كلباء'],
      'إمارة عجمان': ['عجمان'],
      'إمارة رأس الخيمة': ['رأس الخيمة'],
      'إمارة الفجيرة': ['الفجيرة'],
      'إمارة أم القيوين': ['أم القيوين'],
    },
    'قطر': {
      'بلدية الدوحة': ['الدوحة', 'اللؤلؤة', 'الدفنة', 'مشيرب'],
      'بلدية الريان': ['الريان', 'معيذر', 'الغرافة'],
      'بلدية الوكرة': ['الوكرة', 'مسيعيد'],
      'بلدية الخور والدخيرة': ['الخور'],
      'بلدية أم صلال': ['أم صلال علي', 'أم صلال محمد'],
      'بلدية الظعاين': ['لوسيل'],
    },
    'الكويت': {
      'محافظة العاصمة': ['الكويت', 'شرق', 'المرقاب', 'المنصورية'],
      'محافظة حولي': ['حولي', 'السالمية', 'سلوى', 'الرميثية'],
      'محافظة الفروانية': ['الفروانية', 'خيطان', 'الجليب'],
      'محافظة الأحمدي': ['الأحمدي', 'الفحيحيل', 'المنقف'],
      'محافظة الجهراء': ['الجهراء', 'الصليبية'],
      'محافظة مبارك الكبير': ['صباح السالم', 'القرين'],
    },
    'سلطنة عمان': {
      'محافظة مسقط': ['مسقط', 'السيب', 'مطرح', 'بوشر', 'العامرات'],
      'محافظة ظفار': ['صلالة', 'طاقة', 'مرباط'],
      'محافظة مسندم': ['خصب', 'دبا'],
      'محافظة البريمي': ['البريمي'],
      'محافظة الداخلية': ['نزوى', 'بهلاء', 'سمائل'],
      'محافظة شمال الباطنة': ['صحار', 'السويق', 'صحم'],
      'محافظة جنوب الباطنة': ['الرستاق', 'بركاء'],
    },
    'البحرين': {
      'محافظة العاصمة': ['المنامة', 'الجفير', 'سترة'],
      'محافظة المحرق': ['المحرق', 'الحد', 'عراد'],
      'المحافظة الشمالية': ['المدينة الشمالية', 'البديع', 'سار'],
      'المحافظة الجنوبية': ['الرفاع', 'مدينة عيسى', 'الزلاق'],
    },

    // -----------------------------------------------------------------
    // 3. دول الشام والعراق واليمن (Levant, Iraq & Yemen)
    // -----------------------------------------------------------------
    'فلسطين': {
      'محافظة القدس': ['القدس', 'العيزرية', 'أبو ديس'],
      'محافظة رام الله والبيرة': ['رام الله', 'البيرة', 'بيتونيا'],
      'محافظة غزة': ['غزة', 'الرمال'],
      'محافظة الخليل': ['الخليل', 'حلحول', 'يطة'],
      'محافظة نابلس': ['نابلس', 'حوارة'],
      'محافظة بيت لحم': ['بيت لحم', 'بيت جالا', 'بيت ساحور'],
      'محافظة جنين': ['جنين', 'يعبد'],
      'محافظة أريحا': ['أريحا'],
      'محافظة خان يونس': ['خان يونس'],
      'محافظة رفح': ['رفح'],
    },
    'الأردن': {
      'محافظة العاصمة (عمان)': ['عمان', 'العبدلي', 'الشميساني', 'الجبيهة', 'مرج الحمام'],
      'محافظة الزرقاء': ['الزرقاء', 'الرصيفة'],
      'محافظة إربد': ['إربد', 'الرمثا'],
      'محافظة العقبة': ['العقبة'],
      'محافظة البلقاء': ['السلط', 'عين الباشا'],
      'محافظة المفرق': ['المفرق'],
      'محافظة الكرك': ['الكرك'],
      'محافظة مادبا': ['مأدبا'],
      'محافظة جرش': ['جرش'],
      'محافظة عجلون': ['عجلون'],
      'محافظة معان': ['معان', 'البتراء'],
      'محافظة الطفيلة': ['الطفيلة'],
    },
    'لبنان': {
      'محافظة بيروت': ['بيروت', 'الأشرفية', 'الحمرا'],
      'محافظة جبل لبنان': ['بعبدا', 'جونيه', 'جبيل', 'الشويفات'],
      'محافظة الشمال': ['طرابلس', 'البترون'],
      'محافظة الجنوب': ['صيدا', 'صور'],
      'محافظة البقاع': ['زحلة', 'شتورة'],
      'محافظة النبطية': ['النبطية'],
      'محافظة بعلبك الهرمل': ['بعلبك'],
    },
    'سوريا': {
      'محافظة دمشق': ['دمشق', 'المزة', 'الميدان'],
      'محافظة ريف دمشق': ['جرمانا', 'قدسيا', 'دوما'],
      'محافظة حلب': ['حلب', 'عفرين'],
      'محافظة حمص': ['حمص', 'تدمر'],
      'محافظة حماة': ['حماة', 'سلمية'],
      'محافظة اللاذقية': ['اللاذقية', 'جبلة'],
      'محافظة طرطوس': ['طرطوس', 'بانياس'],
      'محافظة درعا': ['درعا'],
      'محافظة دير الزور': ['دير الزور'],
      'محافظة إدلب': ['إدلب'],
      'محافظة الرقة': ['الرقة'],
      'محافظة الحسكة': ['الحسكة', 'القامشلي'],
      'محافظة السويداء': ['السويداء'],
    },
    'العراق': {
      'محافظة بغداد': ['بغداد', 'الكرخ', 'الرصافة', 'المنصور'],
      'محافظة البصرة': ['البصرة', 'الزبير', 'الفاو'],
      'محافظة أربيل': ['أربيل', 'عنكاوا'],
      'محافظة نينوى': ['الموصل', 'تلعفر'],
      'محافظة النجف': ['النجف', 'الكوفة'],
      'محافظة كربلاء': ['كربلاء'],
      'محافظة السليمانية': ['السليمانية'],
      'محافظة دهوك': ['دهوك', 'زاخو'],
      'محافظة كركوك': ['كركوك'],
      'محافظة الأنبار': ['الرمادي', 'الفلوجة'],
      'محافظة بابل': ['الحلة'],
      'محافظة ذي قار': ['الناصرية'],
      'محافظة صلاح الدين': ['تكريت', 'سامراء'],
      'محافظة ديالي': ['بعقوبة'],
    },
    'اليمن': {
      'أمانة العاصمة': ['صنعاء'],
      'محافظة عدن': ['عدن', 'كريتر', 'الشيخ عثمان'],
      'محافظة تعز': ['تعز'],
      'محافظة الحديدة': ['الحديدة'],
      'محافظة حضرموت': ['المكلا', 'سيئون'],
      'محافظة إب': ['إب'],
      'محافظة ذمار': ['ذمار'],
      'محافظة مأرب': ['مأرب'],
      'محافظة شبوة': ['عتق'],
    },

    // -----------------------------------------------------------------
    // 4. دول دولية أخرى
    // -----------------------------------------------------------------
    'فرنسا (France)': {
      'Île-de-France': ['Paris', 'Boulogne-Billancourt', 'Versailles'],
      'Provence-Alpes-Côte d\'Azur': ['Marseille', 'Nice', 'Cannes'],
      'Auvergne-Rhône-Alpes': ['Lyon', 'Grenoble'],
    },
    'تركيا (Turkey)': {
      'إسطنبول (Istanbul)': ['الفاتح', 'تقسيم', 'باشاك شهير', 'كاديكوي'],
      'أنقرة (Ankara)': ['أنقرة', 'تشانكايا'],
      'أنطاليا (Antalya)': ['أنطاليا', 'ألانيا'],
    },
    'دولة أخرى': {
      'المنطقة الرئيسية': ['المدينة الرئيسية'],
    }
  };

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  void _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getClients();
      if (mounted) {
        setState(() {
          _clients = data.map((e) => ClientUser.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء جلب قائمة الحرفاء')));
      }
    }
  }

  List<ClientUser> get _filteredClients {
    if (_searchQuery.trim().isEmpty) return _clients;
    final query = _searchQuery.toLowerCase();
    return _clients.where((c) {
      return c.username.toLowerCase().contains(query) ||
          c.fullName.toLowerCase().contains(query) ||
          c.companyName.toLowerCase().contains(query) ||
          c.country.toLowerCase().contains(query);
    }).toList();
  }

  // نافذة إضافة / تعديل الحريف المتقدمة والمتجاوبة
  void _showClientFormModal({ClientUser? client}) {
    final bool isEditing = client != null;
    final usernameCtrl = TextEditingController(text: client?.username ?? '');
    final passwordCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController(text: client?.fullName ?? '');
    final companyCtrl = TextEditingController(text: client?.companyName ?? '');

    // إعدادات الموقع القابلة للاختيار التلقائي مع دعم الخيار الفارغ
    String selectedCountry = client != null && client.country.isNotEmpty && _locationData.containsKey(client.country)
        ? client.country
        : _locationData.keys.first;

    String? selectedState = (client != null && client.state.isNotEmpty) ? client.state : null;
    String? selectedCity = (client != null && client.city.isNotEmpty) ? client.city : null;

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 650;

            // تحديث القوائم الفرعية تلقائياً عند تغيير الدولة أو الولاية
            Map<String, List<String>> statesMap = _locationData[selectedCountry] ?? {};
            List<String> statesList = statesMap.keys.toList();

            List<String> citiesList = (selectedState != null && statesMap.containsKey(selectedState))
                ? statesMap[selectedState]!
                : [];

            // قائمة خيارات الولايات مع الخيار الفارغ الاختياري
            List<DropdownMenuItem<String?>> stateItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('-- بدون تحديد (اختياري) --', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
              ...statesList.map((s) => DropdownMenuItem<String?>(
                value: s,
                child: Text(s, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
              )),
            ];

            // قائمة خيارات المدن مع الخيار الفارغ الاختياري
            List<DropdownMenuItem<String?>> cityItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('-- بدون تحديد (اختياري) --', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
              ...citiesList.map((ci) => DropdownMenuItem<String?>(
                value: ci,
                child: Text(ci, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
              )),
            ];

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: isMobile ? screenWidth : 680,
                padding: EdgeInsets.all(isMobile ? 18 : 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الهيدر
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEditing ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                              color: isEditing ? Colors.amber.shade700 : Colors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'تعديل بيانات الحريف' : 'إضافة حريف جديد',
                                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text('إدخال بيانات الهوية والعنوان والشركة للحريف', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // 1. البيانات الشخصية والحساب (مطلوبة)
                      _buildSectionHeader('بيانات الحساب والهوية', Icons.person_outline_rounded, isDark),
                      const SizedBox(height: 14),

                      if (isMobile) ...[
                        _buildTextField(fullNameCtrl, 'الاسم واللقب', 'مثال: وليد الحساني', Icons.badge_outlined, isDark),
                        const SizedBox(height: 14),
                        _buildTextField(usernameCtrl, 'اسم المستخدم (Username)', 'مثال: walid_h', Icons.account_circle_outlined, isDark),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildTextField(fullNameCtrl, 'الاسم واللقب', 'مثال: وليد الحساني', Icons.badge_outlined, isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildTextField(usernameCtrl, 'اسم المستخدم (Username)', 'مثال: walid_h', Icons.account_circle_outlined, isDark)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // كلمة المرور
                      _buildTextField(
                        passwordCtrl, 
                        isEditing ? 'كلمة المرور (أتركها فارغة للعدم التغيير)' : 'كلمة المرور', 
                        '********', 
                        Icons.lock_outline_rounded, 
                        isDark,
                        isObscure: true
                      ),

                      const SizedBox(height: 24),

                      // 2. بيانات الشركة والموقع (اختيارية بالكامل)
                      _buildSectionHeader('الشركة والعنوان (اختياري)', Icons.business_outlined, isDark),
                      const SizedBox(height: 14),

                      // اسم الشركة
                      _buildTextField(companyCtrl, 'اسم الشركة (اختياري)', 'مثال: وكالة الزلام للإعلانات', Icons.domain_outlined, isDark),
                      const SizedBox(height: 14),

                      // القوائم المنسدلة التفاعلية الآلية للموقع
                      Column(
                        children: [
                          // الدولة (مطلوبة)
                          DropdownButtonFormField<String>(
                            initialValue: selectedCountry,
                            decoration: _buildInputDecoration('الدولة', Icons.public_rounded, isDark),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: _locationData.keys.map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCountry = val;
                                  selectedState = null;
                                  selectedCity = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          if (isMobile) ...[
                            // الولاية (اختياري مع خيار بدون تحديد)
                            DropdownButtonFormField<String?>(
                              initialValue: selectedState,
                              decoration: _buildInputDecoration('الولاية / المحافظة (اختياري)', Icons.map_outlined, isDark),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: stateItems,
                              onChanged: (val) {
                                setModalState(() {
                                  selectedState = val;
                                  selectedCity = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            // المدينة (اختياري مع خيار بدون تحديد)
                            DropdownButtonFormField<String?>(
                              initialValue: selectedCity,
                              decoration: _buildInputDecoration('المدينة / البلدية (اختياري)', Icons.location_city_outlined, isDark),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: cityItems,
                              onChanged: (val) {
                                setModalState(() => selectedCity = val);
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: selectedState,
                                    decoration: _buildInputDecoration('الولاية / المحافظة (اختياري)', Icons.map_outlined, isDark),
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    items: stateItems,
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedState = val;
                                        selectedCity = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: selectedCity,
                                    decoration: _buildInputDecoration('المدينة / البلدية (اختياري)', Icons.location_city_outlined, isDark),
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    items: cityItems,
                                    onChanged: (val) {
                                      setModalState(() => selectedCity = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // الأزرار
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (usernameCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة اسم المستخدم')));
                                      return;
                                    }
                                    if (!isEditing && passwordCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كلمة المرور')));
                                      return;
                                    }

                                    setModalState(() => isSaving = true);
                                    try {
                                      if (isEditing) {
                                        await ApiService().editClient(
                                          client.id,
                                          usernameCtrl.text.trim(),
                                          passwordCtrl.text.trim(),
                                          fullName: fullNameCtrl.text.trim(),
                                          country: selectedCountry,
                                          state: selectedState ?? '',
                                          city: selectedCity ?? '',
                                          companyName: companyCtrl.text.trim(),
                                        );
                                      } else {
                                        await ApiService().createClient(
                                          usernameCtrl.text.trim(),
                                          passwordCtrl.text.trim(),
                                          fullName: fullNameCtrl.text.trim(),
                                          country: selectedCountry,
                                          state: selectedState ?? '',
                                          city: selectedCity ?? '',
                                          companyName: companyCtrl.text.trim(),
                                        );
                                      }

                                      if (!dialogCtx.mounted || !mounted) return;
                                      Navigator.pop(dialogCtx);
                                      _fetchClients();
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(isEditing ? Icons.save_rounded : Icons.person_add_rounded, size: 18),
                            label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة الحريف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, IconData icon, bool isDark, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
      decoration: _buildInputDecoration(label, icon, isDark, hint: hint),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool isDark, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, size: 20, color: Colors.blue),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
    );
  }

  void _confirmDeleteClient(ClientUser client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحريف'),
        content: Text('هل أنت متأكد من حذف الحريف "${client.username}"؟ سينتج عن ذلك حذف كافة المشاريع والمهام التابعة له.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService().deleteClient(client.id);
                if(!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                _fetchClients();
              } catch (e) {
                if(!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحذف')));
              }
            },
            child: const Text('نعم، احذف'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(AppLocalizations.tr('client_management_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            elevation: 1,
            shadowColor: Colors.black12,
            actions: [
              buildLanguageSelector(isDark),
              const SizedBox(width: 8),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, _) {
                  return IconButton(
                    icon: Icon(mode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
                        color: isDark ? Colors.amber : const Color(0xFF1E293B)),
                    tooltip: AppLocalizations.tr('theme_toggle'),
                    onPressed: () {
                      themeNotifier.value = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                    },
                  );
                }
              ),
              const SizedBox(width: 16),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showClientFormModal(),
            label: Text(AppLocalizations.tr('add_new_client')),
            icon: const Icon(Icons.person_add_rounded),
            backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.tr('search_clients_placeholder'),
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _filteredClients.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.people_outline_rounded, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(AppLocalizations.tr('no_clients_found'), style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredClients.length,
                                  itemBuilder: (ctx, i) {
                                    final c = _filteredClients[i];
                                    final String displayName = c.fullName.isNotEmpty ? c.fullName : c.username;
                                    final String locationStr = [c.country, c.state, c.city].where((s) => s.isNotEmpty).join(' - ');

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(20),
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.person_rounded, color: Colors.blue, size: 28),
                                        ),
                                        title: Row(
                                          children: [
                                            Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                            const SizedBox(width: 10),
                                            if (c.companyName.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.business_rounded, size: 12, color: Colors.purple),
                                                    const SizedBox(width: 4),
                                                    Text(c.companyName, style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Text('${AppLocalizations.tr('account_username')}: @${c.username}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                                            if (locationStr.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(locationStr, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text('${c.projectsCount} ${AppLocalizations.tr('projects_count_label')}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                              tooltip: AppLocalizations.tr('edit'),
                                              onPressed: () => _showClientFormModal(client: c),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                              tooltip: AppLocalizations.tr('delete'),
                                              onPressed: () => _confirmDeleteClient(c),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
