// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  // ── General ──────────────────────────────────────────────
  @override String get appTitle => 'Walk Algarve';
  @override String get loading => 'A carregar...';
  @override String get close => 'Fechar';
  @override String get back => 'Voltar';
  @override String get start => 'Iniciar';
  @override String get description => 'Descrição';

  // ── Navigation / Drawer ──────────────────────────────────
  @override String get zones => 'Zonas';
  @override String get trails => 'Trilhos';
  @override String get history => 'Histórico';
  @override String get profile => 'Perfil';
  @override String get settings => 'Definições';
  @override String get logout => 'Sair';
  @override String get favorites => 'Favoritos';
  @override String get explore => 'Explorar';
  @override String get account_section => 'Conta';
  @override String get close_menu => 'Fechar menu';

  // ── Auth ─────────────────────────────────────────────────
  @override String get login => 'Entrar';
  @override String get register => 'Registar';
  @override String get account => 'Ainda não tem conta?';
  @override String get email_label => 'Email';
  @override String get password_label => 'Palavra-passe';
  @override String get confirm_password => 'Confirmar palavra-passe';
  @override String get username_label => 'Nome de utilizador';
  @override String get fill_all_fields => 'Por favor preencha todos os campos.';
  @override String get login_success => 'Login efetuado com sucesso!';
  @override String get login_failed => 'Falha no login.';
  @override String get passwords_no_match => 'As palavras-passe não coincidem.';
  @override String get register_requires_internet => 'Precisa de estar ligado à internet para se registar.';
  @override String get register_success => 'Registo efetuado com sucesso! Por favor faça login.';
  @override String get register_failed => 'Falha no registo.';
  @override String get no_connection_login => 'Sem conexão — precisa fazer login online primeiro.';
  @override String get session_expired => 'Sessão expirada — por favor faça login novamente.';

  // ── Zones ─────────────────────────────────────────────────
  @override String get aboutZone => 'Sobre esta zona';
  @override String get viewTrails => 'Ver trilhos';
  @override String get unlockZone => 'Comprar zona';
  @override String get seeMore => 'Ver mais';
  @override String get no_zones_available => 'Nenhuma zona disponível.';
  @override String get select_municipality => 'Selecionar município';
  @override String get show_all => 'Mostrar todas';
  @override String get no_description => 'Sem descrição disponível.';
  @override String get redirecting_purchase => 'A redirecionar para a compra...';

  // ── Trails ────────────────────────────────────────────────
  @override String get no_trails_available => 'Nenhum trilho disponível.';
  @override String get untitled_trail => 'Trilho sem título';
  @override String get bike_friendly => 'Aceita bicicletas';
  @override String get no_bikes => 'Sem bicicletas';

  // ── Trail Map ─────────────────────────────────────────────
  @override String get start_trail_title => 'Iniciar trilho?';
  @override String get start_trail_body => 'Deseja iniciar o percurso agora?';

  // ── POIs ──────────────────────────────────────────────────
  @override String get poi_default_name => 'Ponto de Interesse';
  @override String get fauna => 'Fauna';
  @override String get flora => 'Flora';
  @override String get geology => 'Geologia';
  @override String get user_messages => 'Mensagens dos utilizadores';
  @override String get no_info => 'Sem informação disponível.';
  @override String get leave_message => 'Deixa uma mensagem';

  // ── Profile ───────────────────────────────────────────────
  @override String get welcome => 'Bem-vindo ao Algarve';
  @override String get completed => 'Concluídos';
  @override String get change_language => 'Alterar idioma';
  @override String get change_password => 'Alterar palavra-passe';
  @override String get manage_offline_maps => 'Gerir mapas offline';
  @override String get trail_history_option => 'Histórico de trilhos';

  // ── Favorites ─────────────────────────────────────────────
  @override String get favorite_added => 'Adicionado aos favoritos';
  @override String get favorite_removed => 'Removido dos favoritos';
  @override String get favorite_added_offline => 'Guardado como favorito (offline)';
  @override String get favorite_removed_offline => 'Removido dos favoritos (offline)';
}
