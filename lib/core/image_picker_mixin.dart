import 'package:biblebookapp/view/constants/constant.dart';
import 'package:image_picker/image_picker.dart';

mixin ImagePickerMixin {
  // get Image
  Future<XFile?> getImageFiles({bool? allowMultiple}) async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (await image.length() > 20000 * 1000) {
        Constants.showToast("The file may not be greater than 20 MB.");
        return null;
      }
      return image;
    } else {
      return null;
    }
  }
}
