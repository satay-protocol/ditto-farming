#[test_only]
module satay_ditto_farming::test_ditto_farming {

    use std::signer;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::aptos_coin;
    use aptos_framework::stake;

    use test_helpers::test_account;

    use liquidswap::router_v2;
    use liquidswap::lp_account;
    use liquidswap::liquidity_pool;
    use liquidswap::curves::{Stable};
    use liquidswap_lp::lp_coin::{LP};

    use ditto_staking::mock_ditto_staking::{Self, StakedAptos};
    use satay_ditto_farming::mock_ditto_farming::{Self, DittoFarmingCoin};
    use liquidity_mining::mock_liquidity_mining;

    use satay::math::pow10;

    const INITIAL_LIQUIDITY: u64 = 25000;
    const DEPOSIT_AMOUNT: u64 = 10;

    const ERR_INITIALIZE: u64 = 1;
    const ERR_DEPOSIT: u64 = 2;
    const ERR_WITHDRAW: u64 = 3;
    const ERR_MANAGER: u64 = 4;
    const ERR_SLIPPAGE_TOLERANCE: u64 = 5;

    fun to_8_dp(amount: u64): u64 {
        amount * pow10(8)
    }

    fun setup_tests(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer,
        initial_liquidity: u64,
        deposit_amount: u64,
    ) {
        stake::initialize_for_test(aptos_framework);
        mock_ditto_staking::initialize_staked_aptos(ditto_staking);
        mock_liquidity_mining::initialize(liquidity_mining);

        test_account::create_account(user);
        test_account::create_account(pool_owner);

        lp_account::initialize_lp_account(
            pool_owner,
            x"064c50436f696e010000000000000000403239383333374145433830334331323945313337414344443138463135393936323344464146453735324143373738443344354437453231454133443142454389021f8b08000000000002ff2d90c16ec3201044ef7c45e44b4eb13160c0957aeab5952af51845d1b22c8995c45860bbfdfce2b4b79dd59b9dd11e27c01b5ce8c44678d0ee75b77fff7c8bc3b8672ba53cc4715bb535aff99eb123789f2867ca27769fce58b83320c6659c0b56f19f36980e21f4beb5207a05c48d54285b4784ad7306a5e8831460add6ce486dc98014aed78e2b521d5525c3d37af034d1e869c48172fd1157fa9afd7d702776199e49d7799ef24bd314795d5c8df1d1c034c77cb883cbff23c64475012a9668dd4c3668a91c7a41caa2ea8db0da7ace3be965274550c1680ed4f615cb8bf343da3c7fa71ea541135279d0774cb7669387fc6c54b15fb48937414101000001076c705f636f696e5c1f8b08000000000002ff35c8b10980301046e13e53fc0338411027b0b0d42a84535048ee82de5521bb6b615ef5f8b2ec960ea412482e0e91488cd5fb1f501dbe1ebd8d14f3329633b24ac63aa0ef36a136d7dc0b3946fd604b00000000000000",
            x"a11ceb0b050000000501000202020a070c170823200a4305000000010003000100010001076c705f636f696e024c500b64756d6d795f6669656c6435e1873b2a1ae8c609598114c527b57d31ff5274f646ea3ff6ecad86c56d2cf8000201020100"
        );
        liquidity_pool::initialize(pool_owner);
        liquidity_pool::register<AptosCoin, StakedAptos, Stable>(pool_owner);

        let user_address = signer::address_of(user);
        coin::register<AptosCoin>(user);
        coin::register<StakedAptos>(user);


        aptos_coin::mint(aptos_framework, user_address, initial_liquidity);
        let apt = coin::withdraw<AptosCoin>(user, initial_liquidity);

        let stapt = mock_ditto_staking::mint_staked_aptos(initial_liquidity);

        let lp = liquidity_pool::mint<AptosCoin, StakedAptos, Stable>(
            apt,
            stapt
        );
        coin::register<LP<AptosCoin, StakedAptos, Stable>>(user);
        coin::deposit(user_address, lp);

        aptos_coin::mint(aptos_framework, user_address, deposit_amount);

        mock_ditto_farming::initialize(ditto_farming);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_initialize(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT),
        );
        assert!(mock_ditto_farming::get_manager_address() == @satay_ditto_farming, ERR_INITIALIZE);
        assert!(mock_ditto_farming::get_lp_slippage_tolerance() == 9500, ERR_INITIALIZE);
        assert!(mock_ditto_farming::get_swap_slippage_tolerance() == 9500, ERR_INITIALIZE);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_deposit(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        let initial_liquidity_amount = to_8_dp(50000);
        let deposit_amount = to_8_dp(1);
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            initial_liquidity_amount,
            deposit_amount
        );
        mock_ditto_farming::deposit(user, deposit_amount);

        let user_farming_coin_balance = coin::balance<DittoFarmingCoin>(signer::address_of(user));
        let farming_account_lp_balance = mock_liquidity_mining::get_lp_amount();

        assert!(user_farming_coin_balance > 0, ERR_DEPOSIT);
        assert!(farming_account_lp_balance > 0, ERR_DEPOSIT);
        assert!(farming_account_lp_balance == user_farming_coin_balance, ERR_DEPOSIT);

        let (apt_reserves, stapt_reserves) = router_v2::get_reserves_size<AptosCoin, StakedAptos, Stable>();
        assert!(apt_reserves == initial_liquidity_amount + deposit_amount / 2, ERR_DEPOSIT);
        assert!(stapt_reserves == initial_liquidity_amount + deposit_amount / 2, ERR_DEPOSIT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_deposit_zero(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        let initial_liquidity_amount = to_8_dp(50000);
        let deposit_amount = to_8_dp(0);
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            initial_liquidity_amount,
            deposit_amount
        );
        mock_ditto_farming::deposit(user, deposit_amount);

        let user_farming_coin_balance = coin::balance<DittoFarmingCoin>(signer::address_of(user));
        let farming_account_lp_balance = mock_ditto_farming::get_lp_reserves_amount();

        assert!(user_farming_coin_balance == 0, ERR_DEPOSIT);
        assert!(farming_account_lp_balance == 0, ERR_DEPOSIT);

        let (apt_reserves, stapt_reserves) = router_v2::get_reserves_size<AptosCoin, StakedAptos, Stable>();
        assert!(apt_reserves == initial_liquidity_amount + deposit_amount / 2, ERR_DEPOSIT);
        assert!(stapt_reserves == initial_liquidity_amount + deposit_amount / 2, ERR_DEPOSIT);
    }


    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_withdraw(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        let initial_liquidity_amount = to_8_dp(50000);
        let deposit_amount = to_8_dp(1);
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            initial_liquidity_amount,
            deposit_amount
        );
        mock_ditto_farming::deposit(user, deposit_amount);

        let user_farming_coin_balance = coin::balance<DittoFarmingCoin>(signer::address_of(user));
        let (
            apt_returned,
            stapt_returned
        ) = router_v2::get_reserves_for_lp_coins<AptosCoin, StakedAptos, Stable>(user_farming_coin_balance);
        let resultant_aptos_balance = apt_returned + router_v2::get_amount_out<StakedAptos, AptosCoin, Stable>(stapt_returned);

        mock_ditto_farming::withdraw(user, user_farming_coin_balance);

        let user_aptos_balance = coin::balance<AptosCoin>(signer::address_of(user));
        assert!(user_aptos_balance == resultant_aptos_balance, 1);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_withdraw_slippage_too_high(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        let initial_liquidity_amount = to_8_dp(100);
        let deposit_amount = to_8_dp(100);
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            initial_liquidity_amount,
            deposit_amount
        );
        mock_ditto_farming::deposit(user, deposit_amount);

        let user_farming_coin_balance = coin::balance<DittoFarmingCoin>(signer::address_of(user));
        mock_ditto_farming::withdraw(user, user_farming_coin_balance);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_withdraw_higher_slippage_tolerance(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        let initial_liquidity_amount = to_8_dp(100);
        let deposit_amount = to_8_dp(100);
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            initial_liquidity_amount,
            deposit_amount
        );
        mock_ditto_farming::deposit(user, deposit_amount);
        mock_ditto_farming::set_swap_slippage_tolerance_bps(ditto_farming, 10);

        let user_farming_coin_balance = coin::balance<DittoFarmingCoin>(signer::address_of(user));
        let (
            apt_returned,
            stapt_returned
        ) = router_v2::get_reserves_for_lp_coins<AptosCoin, StakedAptos, Stable>(user_farming_coin_balance);
        let resultant_aptos_balance = apt_returned + router_v2::get_amount_out<StakedAptos, AptosCoin, Stable>(stapt_returned);

        mock_ditto_farming::withdraw(user, user_farming_coin_balance);
        let user_aptos_balance = coin::balance<AptosCoin>(signer::address_of(user));
        assert!(user_aptos_balance == resultant_aptos_balance, 1);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_set_manager(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        mock_ditto_farming::set_manager_address(ditto_farming, signer::address_of(user));
        assert!(mock_ditto_farming::get_manager_address() == signer::address_of(ditto_farming), ERR_MANAGER);
        mock_ditto_farming::accept_new_manager(user);
        assert!(mock_ditto_farming::get_manager_address() == signer::address_of(user), ERR_MANAGER);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_set_manager_unauthorized(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        mock_ditto_farming::set_manager_address(user, signer::address_of(user));
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99,
        user2 = @0x98
    )]
    #[expected_failure]
    public fun test_accept_manager_unauthorized(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer,
        user2: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        mock_ditto_farming::set_manager_address(ditto_farming, signer::address_of(user));
        mock_ditto_farming::accept_new_manager(user2);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_set_lp_slippage_tolerance(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let lp_slippage_tolerance_bps = 100;
        mock_ditto_farming::set_lp_slippage_tolerance_bps(ditto_farming, lp_slippage_tolerance_bps);
        assert!(mock_ditto_farming::get_lp_slippage_tolerance() == lp_slippage_tolerance_bps, ERR_SLIPPAGE_TOLERANCE);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_set_lp_slippage_tolerance_unauthorized(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let lp_slippage_tolerance_bps = 100;
        mock_ditto_farming::set_lp_slippage_tolerance_bps(user, lp_slippage_tolerance_bps);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_set_lp_slippage_tolerance_too_high(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let lp_slippage_tolerance_bps = 10001;
        mock_ditto_farming::set_lp_slippage_tolerance_bps(ditto_farming, lp_slippage_tolerance_bps);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    public fun test_set_swap_slippage_tolerance(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let swap_slippage_tolerance_bps = 100;
        mock_ditto_farming::set_swap_slippage_tolerance_bps(ditto_farming, swap_slippage_tolerance_bps);
        assert!(mock_ditto_farming::get_swap_slippage_tolerance() == swap_slippage_tolerance_bps, ERR_SLIPPAGE_TOLERANCE);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_set_swap_slippage_tolerance_unauthorized(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let swap_slippage_tolerance_bps = 100;
        mock_ditto_farming::set_swap_slippage_tolerance_bps(user, swap_slippage_tolerance_bps);
    }

    #[test(
        aptos_framework = @aptos_framework,
        pool_owner = @liquidswap,
        ditto_farming = @satay_ditto_farming,
        ditto_staking = @ditto_staking,
        liquidity_mining = @liquidity_mining,
        user = @0x99
    )]
    #[expected_failure]
    public fun test_set_swap_slippage_tolerance_too_high(
        aptos_framework: &signer,
        pool_owner: &signer,
        ditto_farming: &signer,
        ditto_staking: &signer,
        liquidity_mining: &signer,
        user: &signer
    ) {
        setup_tests(
            aptos_framework,
            pool_owner,
            ditto_farming,
            ditto_staking,
            liquidity_mining,
            user,
            to_8_dp(INITIAL_LIQUIDITY),
            to_8_dp(DEPOSIT_AMOUNT)
        );
        let swap_slippage_tolerance_bps = 10001;
        mock_ditto_farming::set_swap_slippage_tolerance_bps(ditto_farming, swap_slippage_tolerance_bps);
    }
}
