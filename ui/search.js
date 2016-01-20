/*global O */

"use strict";

var view = new O.View({

    id: 'search',

    allowTextSelection: true,

    query: '',
    start: '',
    end:   '',

    submitQuery: function ( event ) {
        if ( O.DOMEvent.lookupKey( event ) === 'enter' ) {
            this.set( 'currentQuery', {
                query: this.get( 'query' ),
                start: this.get( 'start' ),
                end:   this.get( 'end' ),
            });
            event.stopPropagation();
        }
    }.on( 'keydown' ),

    currentQuery: {},
    currentRequest: null,

    runQuery: function () {
        var request = this.get( 'currentRequest' );
        if ( request !== null ) {
            request.abort();
        }

        var query = this.get( 'currentQuery' ) || {};
        if ( query.query === '' ) {
            this.set( 'results', {} );
            return;
        }

        var app = this;
        request = new O.HttpRequest({
            url: "/search",
            data: [
                "query=" + encodeURIComponent( query.query ),
                "start=" + encodeURIComponent( query.start ),
                "end="   + encodeURIComponent( query.end ),
            ].join('&'),
            success: function ( event ) {
                // XXX error checks
                app.set( 'currentRequest', null );
                app.get( 'spinner' ).set( 'hidden', true );
                app.set( 'results', JSON.parse( event.data ) );
            }.on( 'io:success' )
        });

        this.set( 'currentRequest', request );

        app.get( 'spinner' ).set( 'hidden', false );

        request.send();
    }.observes( 'currentQuery' ),

    results: {},
    error: '',

    formattedResults: function () {
        var results = this.get( 'results' );
        this.set( 'error', results.error || '' );

        var matches = results.matches || [];
        var query = results.query || '';

        var terms = results.terms || [];
        var termRegex = new RegExp( '(' + terms.join('|') + ')', 'g' );

        var output = matches.sort( function (a, b) {
            var ta = a.timestamp;
            var tb = b.timestamp;
            return ( ( ta == tb ) ? 0 : ( ( ta > tb ) ? 1 : -1 ) );
        }).map( function ( match ) {
            var pid = match.pid ? '[' + match.pid + ']' : ''
            return '%s %s %s%s:%s'
                .format( match.timestamp, match.host, match.program, pid, match.message )
                .escapeHTML()
                .replace( termRegex, '<span>$1</span>' );
        }).join( "\n" );
        return output;
    }.property( 'results' ),

    spinner: null,

    draw: function ( layer, Element, el ) {
        let spinner = el( 'div', { class: 'spinner', hidden: true }, [
            el( 'div', { class: 'bounce1' }),
            el( 'div', { class: 'bounce2' }),
            el( 'div', { class: 'bounce3' })
        ]);
        this.set( 'spinner', spinner );
        return [
            el( 'h1', [ 'Log search' ]),
            el( 'div#query-box', [
                new O.TextView({
                    id: 'start',
                    placeholder: 'start date',
                    value: new O.Binding({
                        isTwoWay: true
                    }).from( 'start', this )
                }),
                new O.TextView({
                    id: 'end',
                    placeholder: 'end date',
                    value: new O.Binding({
                        isTwoWay: true
                    }).from( 'end', this )
                }),
                new O.TextView({
                    id: 'query',
                    placeholder: 'query string',
                    value: new O.Binding({
                        isTwoWay: true
                    }).from( 'query', this )
                }),
            ]),
            spinner,
            el( 'div#error', {
                text: O.bind( 'error', this )
            }),
            el( 'pre', {
                html: O.bind( 'formattedResults', this )
            })
        ];
    }
});

new O.RootView( document ).insertView( view );
