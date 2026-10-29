import 'package:flutter/material.dart';

import '../models/cliente/cliente_response.dart';
import '../services/remote/cliente_service.dart';
import '../services/remote/libro_service.dart';
import '../services/remote/venta_service.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/home';
  static const resetPassword = '/reset-password';
  static const books = '/books';
  static const createBook = '/books/create';
  static const clients = '/clients';
  static const editClient = '/clients/edit';
  static const sales = '/sales';
  static const createSale = '/sales/create';
  static const saleDetail = '/sales/detail';
}

class LibrosRouteArgs {
  const LibrosRouteArgs({this.onLogout});

  final VoidCallback? onLogout;
}

class ClientesRouteArgs {
  const ClientesRouteArgs({this.service});

  final ClienteService? service;
}

class EditarClienteRouteArgs {
  const EditarClienteRouteArgs({required this.cliente, this.service});

  final ClienteResponse cliente;
  final ClienteService? service;
}

class VentasRouteArgs {
  const VentasRouteArgs({this.service});

  final VentaService? service;
}

class CrearVentaRouteArgs {
  const CrearVentaRouteArgs({
    this.ventaService,
    this.clienteService,
    this.libroService,
  });

  final VentaService? ventaService;
  final ClienteService? clienteService;
  final LibroService? libroService;
}

class ConsultarVentaRouteArgs {
  const ConsultarVentaRouteArgs({this.ventaId, this.service});

  final int? ventaId;
  final VentaService? service;
}
