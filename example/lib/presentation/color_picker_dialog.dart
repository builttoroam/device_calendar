import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ColorPickerDialog {
  static Future<Color?> selectColorDialog(List<Color> colors, BuildContext context) async {
    return await showDialog<Color>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const Text('Select color'),
              children: [
                ...colors.map((color) =>
                    SimpleDialogOption(
                      onPressed: () { Navigator.pop(context, color); },
                      child:  Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color),
                      ),
                    )
                )]
          );
        }
    );
  }
}