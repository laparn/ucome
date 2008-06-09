proc fas_init { } {
	global LANGUAGE
	set LANGUAGE ""

	fas_session::init
	fas_user::init
	fas_stat::init
}
