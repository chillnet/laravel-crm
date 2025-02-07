@component('admin::emails.layouts.master')
    <div style="text-align: center;">
        @include('layout.logo')
    </div>

    <div style="padding: 30px;">
        <div style="font-size: 20px;color: #242424;line-height: 30px;margin-bottom: 34px;">
            <p style="font-size: 16px;color: #5E5E5E;line-height: 24px;">
                {{ __('admin::app.mail.forget-password.dear', ['name' => $user_name]) }},
            </p>

            <p style="font-size: 16px;color: #5E5E5E;line-height: 24px;">
                {{ __('admin::app.mail.user.create-body') }}
            </p>
        </div>
    </div>
@endcomponent
