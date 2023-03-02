<a href="{{ config('app.url') }}">
    {{-- You may use plain text as a logo instead of image --}}
    @include('layout.logo', ['height' => $height ?? '', 'width' => $width ?? ''])

    {{--Text Logo--}}

</a>
