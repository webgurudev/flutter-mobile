import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/ui/quote/edit/quote_edit_details_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/edit/quote_edit_items_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/edit/quote_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_item_selector.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/refresh_icon_button.dart';

class QuoteEdit extends StatefulWidget {
  final QuoteEditVM viewModel;

  const QuoteEdit({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  @override
  _QuoteEditState createState() => _QuoteEditState();
}

class _QuoteEditState extends State<QuoteEdit>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const kDetailsScreen = 0;
  static const kItemScreen = 1;

  @override
  void initState() {
    super.initState();

    final invoice = widget.viewModel.quote;
    final invoiceItem = widget.viewModel.quoteItem;

    final index = invoice.invoiceItems.contains(invoiceItem)
        ? kItemScreen
        : kDetailsScreen;
    _controller = TabController(vsync: this, length: 2, initialIndex: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final invoice = viewModel.quote;

    return WillPopScope(
      onWillPop: () async {
        viewModel.onBackPressed();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(invoice.isNew
              ? localization.newQuote
              : '${localization.quote} ${viewModel.origQuote.invoiceNumber}'),
          actions: <Widget>[
            RefreshIconButton(
              icon: Icons.cloud_upload,
              tooltip: localization.save,
              isVisible: !invoice.isDeleted,
              isSaving: widget.viewModel.isSaving,
              isDirty: invoice.isNew || invoice != viewModel.origQuote,
              onPressed: () {
                if (!_formKey.currentState.validate()) {
                  return;
                }

                widget.viewModel.onSavePressed(context);
              },
            )
          ],
          bottom: TabBar(
            controller: _controller,
            //isScrollable: true,
            tabs: [
              Tab(
                text: localization.details,
              ),
              Tab(
                text: localization.items,
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _controller,
            children: <Widget>[
              QuoteEditDetailsScreen(),
              QuoteEditItemsScreen(),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          shape: CircularNotchedRectangle(),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              '${localization.total}: ${formatNumber(invoice.calculateTotal(viewModel.company.enableInclusiveTaxes), context, clientId: viewModel.quote.clientId)}',
              style: TextStyle(
                //color: Theme.of(context).selectedRowColor,
                color: Colors.white,
                fontSize: 18.0,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColorDark,
          onPressed: () {
            showDialog<InvoiceItemSelector>(
                context: context,
                builder: (BuildContext context) {
                  return InvoiceItemSelector(
                    onItemsSelected: (items) {
                      viewModel.onItemsAdded(items);
                      _controller.animateTo(kItemScreen);
                    },
                  );
                });
          },
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: localization.addItem,
        ),
      ),
    );
  }
}