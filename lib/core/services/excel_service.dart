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

    // Separate calls into 3 categories
    final answeredCalls = calls.where((call) => call.isAnswered).toList();
    final noAnswerCalls = calls.where((call) => call.isNotAnswered).toList();
    final pendingCalls = calls.where((call) => call.isPending).toList();

    // Headers
    List<String> headers = [
      'Customer Name',
      'Phone Number',
      'Status',
      'Call Date',
      'Call Time'
    ];

    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // 1. Create "Answered Calls" sheet
    if (answeredCalls.isNotEmpty) {
      Sheet answeredSheet = excel['Answered (تم الرد)'];
      _addHeadersToSheet(answeredSheet, headers, headerStyle);
      _addCallsToSheet(answeredSheet, answeredCalls);
    }

    // 2. Create "No Answer" sheet
    if (noAnswerCalls.isNotEmpty) {
      Sheet noAnswerSheet = excel['No Answer (لم يتم الرد)'];
      _addHeadersToSheet(noAnswerSheet, headers, headerStyle);
      _addCallsToSheet(noAnswerSheet, noAnswerCalls);
    }

    // 3. Create "Pending" sheet
    if (pendingCalls.isNotEmpty) {
      Sheet pendingSheet = excel['Pending (بانتظار الاتصال)'];
      _addHeadersToSheet(pendingSheet, headers, headerStyle);
      _addCallsToSheet(pendingSheet, pendingCalls);
    }

    // Remove default sheet (must be done after adding others in some excel package versions)
    if (excel.sheets.containsKey("Sheet1")) {
      excel.delete("Sheet1");
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

  void _addHeadersToSheet(
      Sheet sheet, List<String> headers, CellStyle headerStyle) {
    for (var i = 0; i < headers.length; i++) {
      var cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
  }

  void _addCallsToSheet(Sheet sheet, List<CallEntry> calls) {
    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final rowIndex = i + 1;

      // Name
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(call.customerName ?? 'Unknown');

      // Phone
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(call.phoneNumber);

      // Status
      String statusText = 'Pending (قيد الانتظار)';
      if (call.isAnswered) {
        statusText = 'Answered (تم الرد)';
      } else if (call.isNotAnswered) {
        statusText = 'No Answer (لم يتم الرد)';
      }

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(statusText);

      // Date & Time
      if (call.calledAt != null) {
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 3, rowIndex: rowIndex))
                .value =
            TextCellValue(DateFormat('yyyy-MM-dd').format(call.calledAt!));

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(DateFormat('HH:mm').format(call.calledAt!));
      } else {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue('-');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue('-');
      }
    }
  }
}
