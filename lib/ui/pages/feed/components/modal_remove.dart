import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../post_viewmodel.dart';

Future<int> showModalRemove({
  @required NewsViewModel news,
  @required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('ልጥፍ ይወገድ?'),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'ሰርዝ',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, news.id);
          },
          child: Text(
            'አስወጋጅ',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    ),
  );
}
