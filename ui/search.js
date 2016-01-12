/*global O */

"use strict";

var view = new O.View({

    id: 'search',

    query: '',

    submitQuery: function ( event ) {
        var key = O.DOMEvent.lookupKey( event );
        if ( key === 'enter' ) {
            var query = this.get( 'query' );
            var currentQuery = this.get( 'currentQuery' );
            if (query !== currentQuery && query !== '') {
                this.set( 'currentQuery', query );
            }
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
        matches.map( function ( match ) {
            var pid = match.pid ? '['+match.pid+']' : ''
            output = output + O.loc( '[_1] [_2] [_3][_4]:[_5]', match.timestamp, match.host, match.program, pid, match.message ) + "\n";
        });
        return output;
    }.property( 'results' ),

    draw: function ( layer, Element, el ) {
        return [
            el( 'h1', [ 'Log search' ]),
            new O.TextView({
                multiline: false,
                expanding: true,
                focussed: true,
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
