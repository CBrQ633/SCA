import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/services/models.dart';

class ExcelService {
  Future<void> generateAndShareCallReport(
      List<CallEntry> calls, String listName) async {
    var excel = Excel.createExcel();

    // Remove default sheet
    if (excel.sheets.containsKey("Sheet1")) {
      excel.delete("Sheet1");
    }

    Sheet sheetObject = excel['Report'];

    // Add Headers
    List<String> headers = [
      'Customer Name',
      'Phone Number',
      'Status',
      'Call Date',
      'Call Time'
    ];

    // Styling headers (basic bold)
    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Add Data
    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final rowIndex = i + 1;

      // Name
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(call.customerName ?? 'Unknown');

      // Phone (Ensure it's treated as string to keep leading zero)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(call.phoneNumber);

      // Status
      String statusText = 'Pending';
      if (call.isAnswered)
        statusText = 'Answered (تم الرد)';
      else if (call.isNotAnswered) statusText = 'No Answer (لم يتم الرد)';

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(statusText);

      // Date & Time
      if (call.calledAt != null) {
        sheetObject
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 3, rowIndex: rowIndex))
                .value =
            TextCellValue(DateFormat('yyyy-MM-dd').format(call.calledAt!));

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(DateFormat('HH:mm').format(call.calledAt!));
      } else {
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue('-');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue('-');
      }
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Report_${listName.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final String filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);

      // Share file
      await Share.shareXFiles([XFile(filePath)],
          text: 'SCA Call Report: $listName');
    }
  }
}
