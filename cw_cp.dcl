//  Dialogdatei zu CP.LSP
//
//  Stand:   21.11.2002
//  Version: 1.0


cp_dlg : dialog {
      label = "Text bearbeiten";
	: edit_box {
		label = "Text";
		key = "dlgText";
		edit_width = 60;
	}
	spacer_1;
	spacer_1;
	ok_cancel;
}
