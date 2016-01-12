/*global O */

"use strict";

var view = new O.View({

    allowTextSelection: true,

    id: 'search',

    query: '',

    submitQuery: function ( event ) {
        if ( O.DOMEvent.lookupKey( event ) === 'enter' ) {
            this.set( 'currentQuery', this.get( 'query' ));
            event.stopPropagation();
        }
    }.on( 'keydown' ),

    currentQuery: '',
    currentRequest: null,

    runQuery: function () {
        var request = this.get( 'currentRequest' );
        if ( request !== null ) {
            request.abort();
        }

        var query = this.get( 'currentQuery' );
        if ( query === '' ) {
            this.set( 'results', {} );
            return;
        }

        var app = this;
        request = new O.HttpRequest({
            url: "/search",
            data: "query=" + encodeURIComponent( this.get( 'currentQuery' )),
            success: function ( event ) {
                // XXX error checks
                app.set( 'results', JSON.parse( event.data ) );
            }.on( 'io:success' )
        });

        this.set( 'currentRequest', request );

        request.send();
    }.observes( 'currentQuery' ),

    results: {},

    formattedResults: function () {
        var output = '';
        var matches = this.get( 'results' ).matches || [];
        matches.sort( function (a, b) {
            var ta = a.timestamp;
            var tb = b.timestamp;
            return ( ( ta == tb ) ? 0 : ( ( ta > tb ) ? 1 : -1 ) );
        }).map( function ( match ) {
            var pid = match.pid ? '[' + match.pid + ']' : ''
            output = output + '%s %s %s%s:%s'.format(match.timestamp, match.host, match.program, pid, match.message) + "\n";
        });
        return output;
    }.property( 'results' ),

    draw: function ( layer, Element, el ) {
        return [
            el( 'h1', [ 'Log search' ]),
            new O.TextView({
                multiline: false,
                expanding: true,
                value: new O.Binding({
                    isTwoWay: true
                }).from( 'query', this )
            }),
            el( 'pre', {
                text: O.bind( 'formattedResults', this )
            })
        ];
    }
});

new O.RootView( document ).insertView( view );
