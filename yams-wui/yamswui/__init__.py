from pyramid.session import UnencryptedCookieSessionFactoryConfig
from pyramid.config import Configurator
from sqlalchemy import engine_from_config

from .models import (
    DBSession,
    Base,
    )


def main(global_config, **settings):
    """ This function returns a Pyramid WSGI application.
    """
    engine = engine_from_config(settings, 'sqlalchemy.')
    DBSession.configure(bind=engine)
    Base.metadata.bind = engine
    my_session_factory = UnencryptedCookieSessionFactoryConfig('yams')
    config = Configurator(settings=settings, session_factory=my_session_factory)
    config.add_static_view('static', 'static', cache_max_age=3600)
    config.add_route('add_source', '/add_source')
    config.add_route('chart', '/chart')
    config.add_route('clear_sources', '/clear_sources')
    config.add_route('data_csv', '/data.csv/{plugin}/{host}')
    config.add_route('dsnames', '/dsnames/{type}/{plugin}')
    config.add_route('home', '/')
    config.add_route('hosts', '/hosts/{type}/{plugin}')
    config.add_route('plugins', '/plugins')
    config.add_route('plugin_instances', '/plugin_instances/{plugin}')
    config.add_route('session', '/session')
    config.add_route('toggle_dsname', '/toggle_dsname/{dsname}')
    config.add_route('toggle_host', '/toggle_host/{host}')
    config.add_route('types', '/types/{plugin}')
    config.add_route('type_instances', '/type_instances/{type}/{plugin}')
    config.scan()
    return config.make_wsgi_app()
